import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_teso/core/widgets/theme_toggle_button.dart';
import 'impulsa_file_downloader.dart';
import 'impulsa_kanban_board.dart';
import 'impulsa_modals.dart';
import 'impulsa_models.dart';

class ImpulsaProjectDetailPage extends StatefulWidget {
  final String projectId;
  final ImpulsaProject initialProject;
  final String currentUid;
  final String currentEmail;
  final String currentName;

  const ImpulsaProjectDetailPage({
    super.key,
    required this.projectId,
    required this.initialProject,
    required this.currentUid,
    required this.currentEmail,
    required this.currentName,
  });

  @override
  State<ImpulsaProjectDetailPage> createState() =>
      _ImpulsaProjectDetailPageState();
}

class _ImpulsaProjectDetailPageState extends State<ImpulsaProjectDetailPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _activeView = 0; // 0: Detalles/Código, 1: Tablero Kanban, 2: Solicitudes
  String _fileSearch = '';
  int _selectedFileIndex = 0;

  bool _isEditable(ImpulsaProject p) {
    if (widget.currentUid.isNotEmpty && p.ownerUid == widget.currentUid) {
      return true;
    }
    return p.ownerEmail == widget.currentEmail ||
        p.memberEmails.contains(widget.currentEmail);
  }

  Future<void> _downloadFile(String fileName, String content) async {
    final ok = await downloadImpulsaFile(
      fileName: fileName,
      textContent: content,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Descargando "$fileName"...'
              : 'La descarga directa solo está disponible en la versión Web.',
        ),
        backgroundColor: ok ? ImpulsaPalette.flagGreen : Colors.orange,
      ),
    );
  }

  Future<void> _updateProject(
      ImpulsaProject p, {
        bool registerMovement = false,
        String? feedback,
      }) async {
    if (registerMovement) {
      await ImpulsaLifecycleService.registerProjectMovement(p);
    } else {
      p.updatedAt = DateTime.now();
      await _db
          .collection('agora_impulsa_projects')
          .doc(widget.projectId)
          .update(p.toMap());
    }

    if (feedback != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedback),
          backgroundColor: ImpulsaPalette.flagGreen,
        ),
      );
    }
  }

  Future<void> _uploadOrReplaceCode(ImpulsaProject p) async {
    final selectedFiles = await FilePicker.pickFiles();
    if (!mounted || selectedFiles.isEmpty) return;

    for (final file in selectedFiles) {
      final bytes = await file.readAsBytes();
      final isBin = file.name.toLowerCase().endsWith('.zip') ||
          file.name.toLowerCase().endsWith('.rar');
      final newFile = ImpulsaFile(
        path: file.name,
        content: isBin
            ? '// Archivo comprimido: ${file.name} (${bytes.length} bytes)'
            : utf8.decode(bytes, allowMalformed: true),
        isBinary: isBin,
      );
      p.files.removeWhere((existing) => existing.path == newFile.path);
      p.files.add(newFile);
    }

    await _updateProject(
      p,
      registerMovement: true,
      feedback: p.availableForDonation
          ? 'Código actualizado · Proyecto marcado como "Disponible para donación"'
          : 'Código actualizado en el repositorio',
    );
  }

  Future<void> _editSelectedFile(ImpulsaProject p, ImpulsaFile file) async {
    final ctrl = TextEditingController(text: file.content);
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pal.card,
        title: Text('Editar ${file.name}',
            style: TextStyle(color: pal.textPrimary)),
        content: SizedBox(
          width: 680,
          height: 360,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            style: TextStyle(
              color: pal.textPrimary,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ImpulsaPalette.buttonGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (saved != null) {
      file.content = saved;
      file.updatedAt = DateTime.now();
      await _updateProject(
        p,
        registerMovement: true,
        feedback: 'Cambios guardados en ${file.name}',
      );
    }
  }

  void _downloadCodeDialog(ImpulsaProject p) {
    final bundle = p.files.isEmpty
        ? '// Este proyecto aún no tiene archivos cargados.'
        : p.files
        .map((f) => '/* ===== ARCHIVO: ${f.path} ===== */\n${f.content}')
        .join('\n\n');
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pal.card,
        title: Text('Código fuente · ${p.name}',
            style: TextStyle(color: pal.textPrimary)),
        content: SizedBox(
          width: 650,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              bundle,
              style: TextStyle(
                color: pal.textPrimary,
                fontFamily: 'monospace',
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        actions: [
          if (p.files.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                final fileName = p.files.length == 1
                    ? p.files.first.name
                    : '${p.name.replaceAll(' ', '_')}_codigo.txt';
                final content =
                p.files.length == 1 ? p.files.first.content : bundle;
                _downloadFile(fileName, content);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Descargar archivo'),
            ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: bundle));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código copiado al portapapeles'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar todo el código'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ImpulsaPalette.buttonGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = ImpulsaPalette(Theme.of(context).brightness == Brightness.dark);

    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('agora_impulsa_projects')
          .doc(widget.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        final project = (snapshot.hasData && snapshot.data!.exists)
            ? ImpulsaProject.fromDoc(snapshot.data!)
            : widget.initialProject;
        final editable = _isEditable(project);

        final int pendingRequestsCount = project.isDonated
            ? 0
            : project.requests.where((r) => r.status == 'pending').length;

        return Scaffold(
          backgroundColor: pal.bg,
          appBar: AppBar(
            backgroundColor: pal.card,
            surfaceTintColor: pal.card,
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    project.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pal.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (project.status == 'solicitado') ...[
                  const SizedBox(width: 10),
                  _headerBadge('Solicitado', ImpulsaPalette.flagGreen),
                ] else if (project.status == 'donado') ...[
                  const SizedBox(width: 10),
                  _headerBadge('Donado', const Color(0xFFD97706)),
                ] else if (project.availableForDonation) ...[
                  const SizedBox(width: 10),
                  _headerBadge('Disponible para donación', pal.primary),
                ],
              ],
            ),
            actions: [
              ThemeToggleButton(color: pal.textPrimary),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _activeView == 1
                      ? ImpulsaKanbanBoardView(
                    project: project,
                    editable: editable,
                    currentMemberEmail: widget.currentEmail,
                    onSaveProject: () =>
                        _updateProject(project, registerMovement: true),
                  )
                      : _activeView == 2
                      ? _buildProjectRequestsView(project, pal)
                      : _buildPanel3DetailsAndCode(project, editable, pal),
                ),
              ),
              if (editable)
                Container(
                  width: 215,
                  margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pal.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pal.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ACCIONES',
                        style: TextStyle(
                          color: pal.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _actionSideButton(
                        pal: pal,
                        label: _activeView == 1
                            ? 'Ver detalles 📄'
                            : 'Ir al tablero 📅',
                        icon: Icons.view_kanban_outlined,
                        active: _activeView == 1,
                        onTap: () => setState(
                                () => _activeView = _activeView == 1 ? 0 : 1),
                      ),
                      const SizedBox(height: 8),
                      if (!project.isRequested && !project.isDonated) ...[
                        _actionSideButton(
                          pal: pal,
                          label: project.published
                              ? 'Ocultar 📱'
                              : 'Publicar 📱',
                          icon: Icons.public_rounded,
                          active: project.published,
                          onTap: () async {
                            project.published = !project.published;
                            await _updateProject(
                              project,
                              feedback: project.published
                                  ? 'Proyecto publicado en Red de Proyectos 📱'
                                  : 'Proyecto retirado de la red pública',
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      _actionSideButton(
                        pal: pal,
                        label: pendingRequestsCount > 0
                            ? 'Solicitudes ⭐ ($pendingRequestsCount)'
                            : 'Solicitudes ⭐',
                        icon: Icons.star_outline_rounded,
                        active: _activeView == 2,
                        onTap: () => setState(
                                () => _activeView = _activeView == 2 ? 0 : 2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _actionSideButton({
    required ImpulsaPalette pal,
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: active ? Colors.black : pal.primary),
      label: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : pal.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: active ? ImpulsaPalette.buttonGreen : pal.subCard,
        side: BorderSide(color: active ? pal.primary : pal.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPanel3DetailsAndCode(
      ImpulsaProject p,
      bool editable,
      ImpulsaPalette pal,
      ) {
    final matchingFiles = p.files
        .where((f) => f.path.toLowerCase().contains(_fileSearch.toLowerCase()))
        .toList();
    if (_selectedFileIndex >= matchingFiles.length) {
      _selectedFileIndex = 0;
    }
    final activeFile =
    matchingFiles.isNotEmpty ? matchingFiles[_selectedFileIndex] : null;

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: pal.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: (v) => setState(() => _fileSearch = v),
                      style: TextStyle(color: pal.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: 'Ir al archivo...',
                        filled: true,
                        fillColor: pal.subCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: pal.border),
                        ),
                      ),
                    ),
                  ),
                  if (editable)
                    OutlinedButton.icon(
                      onPressed: () => _uploadOrReplaceCode(p),
                      icon: Icon(Icons.upload_file_rounded,
                          size: 18, color: pal.primary),
                      label: Text('Agregar archivo',
                          style: TextStyle(color: pal.textPrimary)),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _downloadCodeDialog(p),
                    icon: Icon(Icons.download_rounded,
                        size: 18, color: pal.primary),
                    label: Text('Descargar código',
                        style: TextStyle(color: pal.textPrimary)),
                  ),
                  const Spacer(),
                  Text(
                    'Publicado: ${fmtImpulsaDate(p.createdAt)} · ${p.updatesCount} actualizaciones',
                    style: TextStyle(
                      color: pal.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: pal.subCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pal.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: pal.border)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 16, color: pal.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Equipo: ${p.team}',
                            style: TextStyle(
                              color: pal.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${matchingFiles.length} archivo(s)',
                            style: TextStyle(
                                color: pal.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (matchingFiles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No hay archivos subidos todavía.',
                          style: TextStyle(color: pal.textSecondary),
                        ),
                      )
                    else
                      ...matchingFiles.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final f = entry.value;
                        final isSelected = idx == _selectedFileIndex;
                        return Material(
                          color: isSelected ? pal.badgeBg : Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedFileIndex = idx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                border: idx < matchingFiles.length - 1
                                    ? Border(
                                    bottom: BorderSide(color: pal.border))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    f.path.contains('/')
                                        ? Icons.folder_outlined
                                        : Icons.description_outlined,
                                    size: 18,
                                    color: pal.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      f.path,
                                      style: TextStyle(
                                        color: pal.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    fmtImpulsaDate(f.updatedAt),
                                    style: TextStyle(
                                      color: pal.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    tooltip: 'Descargar ${f.name}',
                                    icon: Icon(Icons.download_rounded,
                                        size: 18, color: pal.primary),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _downloadFile(f.name, f.content),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activeFile != null
                          ? 'Vista previa: ${activeFile.path}'
                          : 'Vista previa del código',
                      style: TextStyle(
                        color: pal.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (activeFile != null)
                    TextButton.icon(
                      onPressed: () =>
                          _downloadFile(activeFile.name, activeFile.content),
                      icon: Icon(Icons.download_rounded,
                          size: 18, color: pal.primary),
                      label: Text('Descargar',
                          style: TextStyle(
                              color: pal.primary, fontWeight: FontWeight.bold)),
                    ),
                  if (editable && activeFile != null && !activeFile.isBinary)
                    TextButton.icon(
                      onPressed: () => _editSelectedFile(p, activeFile),
                      icon: Icon(Icons.edit_note_rounded, color: pal.primary),
                      label: Text('Editar archivo',
                          style: TextStyle(
                              color: pal.primary, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints:
                const BoxConstraints(minHeight: 160, maxHeight: 280),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: pal.codeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pal.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    activeFile?.content ??
                        '// Selecciona un archivo de la lista para visualizar su código.',
                    style: const TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: pal.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descripción general',
                  style: TextStyle(
                      color: pal.textPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(p.description, style: TextStyle(color: pal.textSecondary)),
              Divider(color: pal.border, height: 24),
              Wrap(
                spacing: 28,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Autores',
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      ...p.members.map(
                            (m) => Text(
                          '• ${m.name} (${m.normalizedEmail})',
                          style: TextStyle(color: pal.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Semestre: ${p.semester}° · Carrera: ${p.degree}',
                          style: TextStyle(color: pal.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Asesor: ${p.professor}',
                          style: TextStyle(color: pal.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        'Inicio: ${fmtImpulsaDate(p.start)}  ·  Cierre: ${fmtImpulsaDate(p.end)}',
                        style: TextStyle(
                            color: pal.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (editable) ...[
                    OutlinedButton.icon(
                      onPressed: () => _uploadOrReplaceCode(p),
                      icon: Icon(Icons.sync_rounded, color: pal.primary),
                      label: Text('Subir código o actualizar',
                          style: TextStyle(color: pal.textPrimary)),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ImpulsaPalette.buttonGreen,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        await _updateProject(p,
                            registerMovement: true,
                            feedback: 'Proyecto guardado');
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save_rounded, color: Colors.black),
                      label: const Text('Guardar'),
                    ),
                  ] else if (!p.isRequested && !p.isDonated)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ImpulsaPalette.buttonGreen,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => showImpulsaRequestModal(
                        context: context,
                        project: p,
                        currentEmail: widget.currentEmail,
                        currentName: widget.currentName,
                      ),
                      icon: const Icon(Icons.send_rounded, color: Colors.black),
                      label: const Text('Solicitar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectRequestsView(ImpulsaProject p, ImpulsaPalette pal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitudes de donación para ${p.name}',
            style: TextStyle(
                color: pal.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Todos los integrantes del equipo deben aceptar la carta de motivos para habilitar la donación por el administrador.',
            style: TextStyle(color: pal.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: p.requests.isEmpty
                ? Center(
              child: Text(
                'Aún no hay solicitudes para este proyecto.',
                style: TextStyle(color: pal.textSecondary),
              ),
            )
                : ListView.separated(
              itemCount: p.requests.length,
              separatorBuilder: (_, __) => Divider(color: pal.border),
              itemBuilder: (_, i) {
                final req = p.requests[i];
                final isDone = req.status == 'donated' ||
                    req.status == 'approved_by_team' ||
                    p.isDonated;
                final statusLabel = req.status == 'donated' || p.isDonated
                    ? 'Donado 🌱'
                    : req.status == 'approved_by_team'
                    ? 'Aceptada'
                    : req.status == 'rejected'
                    ? 'Rechazada'
                    : 'Pendiente';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pal.badgeBg,
                    child: Icon(Icons.description_outlined,
                        color: pal.primary),
                  ),
                  title: Text(
                    'Equipo: ${req.teamName} · Semestre ${req.semester}° (${req.group})',
                    style: TextStyle(
                        color: pal.textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Estado: $statusLabel · Votos: ${req.acceptedCount}/${req.memberVotes.length} aceptados · Carta: ${req.motivationLetterFileName}',
                    style: TextStyle(color: pal.textSecondary),
                  ),
                  trailing: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDone
                          ? pal.textSecondary.withValues(alpha: 0.25)
                          : ImpulsaPalette.buttonGreen,
                      foregroundColor:
                      isDone ? pal.textPrimary : Colors.black,
                    ),
                    onPressed: () => showImpulsaRequestReviewModal(
                      context: context,
                      project: p,
                      request: req,
                      currentEmail: widget.currentEmail,
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.black),
                    label: const Text('Revisar carta'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}