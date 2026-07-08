import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scanned_document.dart';
import '../services/document_store_service.dart';
import '../widgets/rename_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = DocumentStoreService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<ScannedDocument> _documents = [];
  int _totalBytes = 0;
  bool _loading = true;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    final snapshot = await _store.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _documents = snapshot.documents;
      _totalBytes = snapshot.totalBytes;
      _loading = false;
    });
  }

  Future<void> _scanDocument() async {
    setState(() => _scanning = true);
    File? scannedFile;
    try {
      scannedFile = await _store.scanDocument();
      if (scannedFile == null) return;

      if (!mounted) return;
      final name = await showRenameDialog(
        context,
        _store.suggestedName(),
        title: 'Nome do documento',
        selectAll: true,
      );
      if (name == null || name.trim().isEmpty) {
        await scannedFile.delete();
        return;
      }

      final document = await _store.saveDocument(scannedFile, name);
      if (!mounted) return;
      setState(() {
        _documents = [document, ..._documents];
        _totalBytes += document.sizeBytes;
      });
    } catch (e) {
      _showError('Nao foi possivel digitalizar o documento: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _openDocument(ScannedDocument document) async {
    final result = await OpenFilex.open(document.path);
    if (result.type != ResultType.done && mounted) {
      _showError('Nao foi possivel abrir o documento: ${result.message}');
    }
  }

  Future<void> _shareDocument(ScannedDocument document) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(document.path)],
        fileNameOverrides: ['${document.name}.pdf'],
      ),
    );
  }

  Future<void> _renameDocument(ScannedDocument document) async {
    final newName = await showRenameDialog(context, document.name);
    if (newName == null || newName.trim().isEmpty) return;
    try {
      final renamed = await _store.rename(document, newName);
      if (!mounted) return;
      setState(() {
        final index = _documents.indexWhere((item) => item.path == document.path);
        if (index >= 0) {
          _documents[index] = renamed;
        }
      });
    } catch (e) {
      _showError('Nao foi possivel renomear o documento: $e');
    }
  }

  Future<void> _deleteDocument(ScannedDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('Tem a certeza que deseja eliminar "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.delete(document);
    if (!mounted) return;
    setState(() {
      _documents = _documents.where((item) => item.path != document.path).toList();
      _totalBytes -= document.sizeBytes;
      if (_totalBytes < 0) _totalBytes = 0;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CB Scanner')),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? _buildEmptyState()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildLibrarySummary()),
                      SliverList.builder(
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          return _DocumentTile(
                            document: document,
                            subtitle:
                                '${_dateFormat.format(document.modifiedAt)} · ${_formatSize(document.sizeBytes)}',
                            onOpen: () => _openDocument(document),
                            onShare: () => _shareDocument(document),
                            onRename: () => _renameDocument(document),
                            onDelete: () => _deleteDocument(document),
                          );
                        },
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _scanDocument,
        icon: _scanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.document_scanner_outlined),
        label: Text(_scanning ? 'A digitalizar...' : 'Digitalizar documento'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ainda nao tem documentos digitalizados',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque em "Digitalizar documento" para usar a camara e criar o seu primeiro PDF.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarySummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_documents.length} documentos · ${_formatSize(_totalBytes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Tooltip(
            message:
                'Limite por digitalizacao: ${DocumentStoreService.highVolumePageLimit} paginas',
            child: Icon(
              Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final ScannedDocument document;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _DocumentTile({
    required this.document,
    required this.subtitle,
    required this.onOpen,
    required this.onShare,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.picture_as_pdf_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(document.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      onTap: onOpen,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'share':
              onShare();
            case 'rename':
              onRename();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'share', child: Text('Partilhar')),
          PopupMenuItem(value: 'rename', child: Text('Renomear')),
          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
      ),
    );
  }
}
