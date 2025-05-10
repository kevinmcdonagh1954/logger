import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../coordinate_formatter.dart';
import '../../../../domain_layer/coordinates/point.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../l10n/app_localizations.dart';

class PointDialog extends StatefulWidget {
  final JobService jobService;
  final String coordinateFormat;
  final Point? existingPoint;
  final VoidCallback? onSuccess;
  final VoidCallback? onDelete;
  final bool allowUseWithoutSaving;
  final String? initialComment;

  const PointDialog({
    super.key,
    required this.jobService,
    required this.coordinateFormat,
    this.existingPoint,
    this.onSuccess,
    this.onDelete,
    this.allowUseWithoutSaving = false,
    this.initialComment,
  });

  static Future<Point?> showAddEditPointDialog({
    required BuildContext context,
    required JobService jobService,
    required String coordinateFormat,
    Point? existingPoint,
    VoidCallback? onSuccess,
    VoidCallback? onDelete,
    bool allowUseWithoutSaving = false,
    String? initialComment,
  }) {
    return showDialog<Point?>(
      context: context,
      builder: (BuildContext context) => PointDialog(
        jobService: jobService,
        coordinateFormat: coordinateFormat,
        existingPoint: existingPoint,
        onSuccess: onSuccess,
        onDelete: onDelete,
        allowUseWithoutSaving: allowUseWithoutSaving,
        initialComment: initialComment,
      ),
    );
  }

  @override
  State<PointDialog> createState() => _PointDialogState();
}

class _PointDialogState extends State<PointDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController commentController;
  late final TextEditingController yController;
  late final TextEditingController xController;
  late final TextEditingController zController;
  late final TextEditingController descriptorController;

  // Focus nodes for coordinate fields
  final yFocusNode = FocusNode();
  final xFocusNode = FocusNode();
  final zFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController(
        text: widget.initialComment ?? widget.existingPoint?.comment);
    yController = TextEditingController(
        text: widget.existingPoint?.y.toString() ?? "0.000");
    xController = TextEditingController(
        text: widget.existingPoint?.x.toString() ?? "0.000");
    zController = TextEditingController(
        text: widget.existingPoint?.z.toString() ?? "0.000");
    descriptorController =
        TextEditingController(text: widget.existingPoint?.descriptor);

    // Add focus listeners for auto-selection
    yFocusNode.addListener(() {
      if (yFocusNode.hasFocus) {
        yController.selection =
            TextSelection(baseOffset: 0, extentOffset: yController.text.length);
      }
    });

    xFocusNode.addListener(() {
      if (xFocusNode.hasFocus) {
        xController.selection =
            TextSelection(baseOffset: 0, extentOffset: xController.text.length);
      }
    });

    zFocusNode.addListener(() {
      if (zFocusNode.hasFocus) {
        zController.selection =
            TextSelection(baseOffset: 0, extentOffset: zController.text.length);
      }
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    yController.dispose();
    xController.dispose();
    zController.dispose();
    descriptorController.dispose();
    yFocusNode.dispose();
    xFocusNode.dispose();
    zFocusNode.dispose();
    super.dispose();
  }

  // Decimal formatter for coordinate fields
  final decimalFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text == '-') return newValue;
    if (newValue.text == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }
    if (newValue.text.contains('.') &&
        newValue.text.indexOf('.') != newValue.text.lastIndexOf('.')) {
      return oldValue;
    }
    if (double.tryParse(newValue.text) != null || newValue.text == '-') {
      return newValue;
    }
    return oldValue;
  });

  bool isCommentValid() {
    if (commentController.text.trim().isEmpty) return false;
    if (widget.existingPoint != null) {
      if (widget.existingPoint!.comment != commentController.text.trim()) {
        return !widget.jobService.points.value.any((p) =>
            p.id != widget.existingPoint!.id &&
            p.comment.toLowerCase() ==
                commentController.text.trim().toLowerCase());
      }
      return true;
    }
    return !widget.jobService.points.value.any((p) =>
        p.comment.toLowerCase() == commentController.text.trim().toLowerCase());
  }

  bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  bool isDataValid() {
    return commentController.text.trim().isNotEmpty &&
        yController.text.isNotEmpty &&
        xController.text.isNotEmpty &&
        zController.text.isNotEmpty &&
        isNumeric(yController.text) &&
        isNumeric(xController.text) &&
        isNumeric(zController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.existingPoint == null ? l10n.addPointDialog : l10n.editPoint,
            style: const TextStyle(fontSize: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCommentValid() ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCommentValid() ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCommentValid() ? Icons.check_circle : Icons.error_outline,
                  color: isCommentValid() ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isCommentValid() ? l10n.validComment : l10n.invalidComment,
                  style: TextStyle(
                    color: isCommentValid() ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: l10n.comment,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      commentController.clear();
                      setState(() {});
                    },
                  ),
                ),
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterComment;
                  }
                  if (!isCommentValid()) {
                    return l10n.commentExists;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: yController,
                focusNode: yFocusNode,
                decoration: InputDecoration(
                  labelText: CoordinateFormatter.getCoordinateLabel(
                      'Y', widget.coordinateFormat),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      yController.text = "0.000";
                      setState(() {});
                    },
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                inputFormatters: [decimalFormatter],
                enabled: isCommentValid(),
              ),
              TextFormField(
                controller: xController,
                focusNode: xFocusNode,
                decoration: InputDecoration(
                  labelText: CoordinateFormatter.getCoordinateLabel(
                      'X', widget.coordinateFormat),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      xController.text = "0.000";
                      setState(() {});
                    },
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                inputFormatters: [decimalFormatter],
                enabled: isCommentValid(),
              ),
              TextFormField(
                controller: zController,
                focusNode: zFocusNode,
                decoration: InputDecoration(
                  labelText: CoordinateFormatter.getCoordinateLabel(
                      'Z', widget.coordinateFormat),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      zController.text = "0.000";
                      setState(() {});
                    },
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                inputFormatters: [decimalFormatter],
                enabled: isCommentValid(),
              ),
              TextFormField(
                controller: descriptorController,
                decoration: InputDecoration(
                  labelText: 'Descriptor',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => descriptorController.clear(),
                  ),
                ),
                maxLength: 20,
                enabled: isCommentValid(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existingPoint != null && widget.onDelete != null)
          TextButton(
            onPressed: isDataValid()
                ? () async {
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 100));
                    widget.onDelete!();
                  }
                : null,
            style: TextButton.styleFrom(
              backgroundColor:
                  isDataValid() ? Colors.red[50] : Colors.grey[200],
              foregroundColor: isDataValid() ? Colors.red : Colors.grey,
            ),
            child: Text(l10n.delete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red[50],
            foregroundColor: Colors.red,
          ),
          child: Text(l10n.cancel),
        ),
        if (widget.allowUseWithoutSaving &&
            widget.existingPoint == null &&
            isDataValid())
          TextButton(
            onPressed: () {
              try {
                final point = Point(
                  id: null,
                  comment: commentController.text.trim(),
                  y: double.parse(yController.text),
                  x: double.parse(xController.text),
                  z: double.parse(zController.text),
                  descriptor: descriptorController.text.isNotEmpty
                      ? descriptorController.text
                      : null,
                );
                Navigator.pop(context, point);
              } catch (e) {
                debugPrint('Error: ${e.toString()}');
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue,
            ),
            child: Text(l10n.add),
          ),
        TextButton(
          onPressed: isCommentValid()
              ? () async {
                  try {
                    final point = Point(
                      id: widget.existingPoint?.id,
                      comment: commentController.text.trim(),
                      y: double.parse(yController.text),
                      x: double.parse(xController.text),
                      z: double.parse(zController.text),
                      descriptor: descriptorController.text.isNotEmpty
                          ? descriptorController.text
                          : null,
                    );

                    if (widget.existingPoint == null) {
                      await widget.jobService.addPoint(point);
                      if (widget.onSuccess != null) widget.onSuccess!();
                      if (mounted) {
                        Navigator.pop(context, point);
                      }
                    } else {
                      await widget.jobService.updatePoint(point);
                      if (widget.onSuccess != null) widget.onSuccess!();
                      if (mounted) {
                        Navigator.pop(context, point);
                      }
                    }
                  } catch (e) {
                    debugPrint('Error: ${e.toString()}');
                  }
                }
              : null,
          style: TextButton.styleFrom(
            backgroundColor:
                isCommentValid() ? Colors.green[50] : Colors.grey[200],
            foregroundColor: isCommentValid() ? Colors.green : Colors.grey,
          ),
          child: Text(
            widget.existingPoint == null
                ? (widget.allowUseWithoutSaving ? l10n.save : l10n.add)
                : l10n.update,
          ),
        ),
      ],
    );
  }
}
