// lib/main.dart
// Chess Assist — FEN in, Stockfish top-3 PV out.

import 'dart:async';
import 'package:flutter/material.dart';
import 'engine_service.dart';
import 'fen_validator.dart';

void main() => runApp(const ChessAssistApp());

class ChessAssistApp extends StatelessWidget {
  const ChessAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Assist',
      theme: ThemeData.dark(useMaterial3: true),
      home: const AssistScreen(),
    );
  }
}

class AssistScreen extends StatefulWidget {
  const AssistScreen({super.key});

  @override
  State<AssistScreen> createState() => _AssistScreenState();
}

class _AssistScreenState extends State<AssistScreen> {
  final _engine = EngineService();
  final _fenController = TextEditingController(
    text: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  );
  final _depthController = TextEditingController(text: '18');
  StreamSubscription? _sub;
  List<EngineLine> _lines = [];
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _engine.start();
    _sub = _engine.lines.listen((l) {
      if (mounted) setState(() => _lines = l);
    });
    if (mounted) setState(() => _ready = true);
  }

  void _run() {
    final err = FenValidator.validate(_fenController.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    final depth = int.tryParse(_depthController.text) ?? 18;
    _engine.analyze(_fenController.text.trim(), depth: depth);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    _fenController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chess Assist')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _fenController,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'FEN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _depthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Depth',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _ready ? _run : null,
                  child: const Text('Analyze'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _engine.stop,
                  child: const Text('Stop'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _lines.length,
                itemBuilder: (_, i) {
                  final l = _lines[i];
                  final score = l.isMate
                      ? '#${l.mateIn}'
                      : '${(l.scoreCp / 100).toStringAsFixed(2)}';
                  return Card(
                    child: ListTile(
                      title: Text('Line ${l.multipv}  ·  $score'),
                      subtitle: Text(
                        'd${l.depth}  ${l.pv}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ), 
      
    );
  }
}
