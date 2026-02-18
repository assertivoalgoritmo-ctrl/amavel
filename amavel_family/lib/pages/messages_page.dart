import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/family_providers.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _textController = TextEditingController();
  late AudioPlayer _audioPlayer;
  late Record _record;
  bool _isRecording = false;
  String? _recordingPath;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _record = Record();
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    _record.dispose();
    super.dispose();
  }

  void _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _record.start(
          path: path,
          encoder: AudioEncoder.aacLc,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar gravação: $e')),
      );
    }
  }

  void _stopRecording() async {
    try {
      final path = await _record.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        _showRecordingOptions(path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao parar gravação: $e')),
      );
    }
  }

  void _showRecordingOptions(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mensagem de Voz'),
        content: const Text('Deseja enviar esta mensagem de voz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendVoiceMessage(path);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _sendVoiceMessage(String path) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      final seniorId = await ref.read(linkedSeniorIdProvider.future);

      if (currentUser == null || seniorId == null) {
        throw 'Usuário ou idoso não encontrado';
      }

      final messagingService = ref.read(messagingServiceProvider);
      final audioFile = File(path);

      await messagingService.sendVoiceMessage(
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Família',
        recipientId: seniorId,
        audioFile: audioFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem enviada!')),
        );
      }

      setState(() => _recordingPath = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar: $e')),
      );
    }
  }

  void _sendTextMessage() async {
    if (_textController.text.trim().isEmpty) return;

    try {
      final currentUser = ref.read(currentUserProvider);
      final seniorId = await ref.read(linkedSeniorIdProvider.future);

      if (currentUser == null || seniorId == null) {
        throw 'Usuário ou idoso não encontrado';
      }

      final messagingService = ref.read(messagingServiceProvider);

      await messagingService.sendTextMessage(
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Família',
        recipientId: seniorId,
        text: _textController.text.trim(),
      );

      _textController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem enviada!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (messageList) {
                if (messageList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    final message = messageList[index];
                    final isSent = message.senderId == currentUser?.uid;

                    return _MessageBubble(
                      message: message,
                      isSent: isSent,
                      onPlayAudio: (messageId) {
                        setState(() => _playingMessageId = messageId);
                      },
                      playingMessageId: _playingMessageId,
                      audioPlayer: _audioPlayer,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Erro: $err'),
              ),
            ),
          ),
          _MessageInput(
            textController: _textController,
            onSendText: _sendTextMessage,
            isRecording: _isRecording,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final Message message;
  final bool isSent;
  final Function(String) onPlayAudio;
  final String? playingMessageId;
  final AudioPlayer audioPlayer;

  const _MessageBubble({
    required this.message,
    required this.isSent,
    required this.onPlayAudio,
    required this.playingMessageId,
    required this.audioPlayer,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });
    widget.audioPlayer.positionStream.listen((p) {
      setState(() => _position = p);
    });
  }

  void _playAudio(String url) async {
    try {
      if (widget.playingMessageId == widget.message.id) {
        if (widget.audioPlayer.playing) {
          await widget.audioPlayer.pause();
        } else {
          await widget.audioPlayer.play();
        }
      } else {
        await widget.audioPlayer.setUrl(url);
        await widget.audioPlayer.play();
        widget.onPlayAudio(widget.message.id);
      }
    } catch (e) {
      print('Erro ao reproduzir áudio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.playingMessageId == widget.message.id &&
        widget.audioPlayer.playing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSent
                ? const Color(0xFF6366F1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.type == MessageType.voice)
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isSent ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            if (widget.message.audioUrl != null) {
                              _playAudio(widget.message.audioUrl!);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: SizedBox(
                            width: 120,
                            child: Slider(
                              value: _position.inSeconds.toDouble(),
                              max: _duration.inSeconds.toDouble(),
                              onChanged: (value) async {
                                await widget.audioPlayer.seek(
                                  Duration(seconds: value.toInt()),
                                );
                              },
                              activeColor: widget.isSent
                                  ? Colors.white
                                  : const Color(0xFF6366F1),
                              inactiveColor: widget.isSent
                                  ? Colors.white30
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.message.transcript != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.message.transcript!,
                          style: TextStyle(
                            color: widget.isSent ? Colors.white : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                )
              else
                Text(
                  widget.message.content,
                  style: TextStyle(
                    color: widget.isSent ? Colors.white : Colors.black,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(widget.message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isSent ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSendText;
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _MessageInput({
    required this.textController,
    required this.onSendText,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          if (!isRecording)
            Expanded(
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
              ),
            )
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Gravando...',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 12),
          if (isRecording)
            FloatingActionButton.small(
              onPressed: onStopRecording,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            )
          else
            Row(
              children: [
                FloatingActionButton.small(
                  onPressed: onStartRecording,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.mic),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: onSendText,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
