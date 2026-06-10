import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:pocketledger/app/theme.dart';

class NfcWriteDialog extends StatefulWidget {
  final String vCardData;

  const NfcWriteDialog({super.key, required this.vCardData});

  @override
  State<NfcWriteDialog> createState() => _NfcWriteDialogState();
}

class _NfcWriteDialogState extends State<NfcWriteDialog> {
  String _status = 'Preparing NFC...';
  bool _isWriting = false;
  bool _isSuccess = false;
  bool _isUnsupported = false;

  @override
  void initState() {
    super.initState();
    _startNfcWrite();
  }

  @override
  void dispose() {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
    super.dispose();
  }

  void _startNfcWrite() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isUnsupported = true;
        _status = 'NFC is not supported or is turned off on this device.';
      });
      return;
    }

    setState(() {
      _isWriting = true;
      _status = 'Hold your physical NFC card or tag close to the back of your phone...';
    });

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          setState(() {
            _status = 'Tag is not NDEF formatted or compatible.';
          });
          await NfcManager.instance.stopSession(errorMessage: 'Incompatible tag.');
          return;
        }

        if (!ndef.isWritable) {
          setState(() {
            _status = 'The detected tag is read-only (not writable).';
          });
          await NfcManager.instance.stopSession(errorMessage: 'Read-only tag.');
          return;
        }

        try {
          // Write vCard as MIME type record
          final ndefRecord = NdefRecord.createMime(
            'text/vcard',
            utf8.encode(widget.vCardData),
          );
          final ndefMessage = NdefMessage([ndefRecord]);

          await ndef.write(ndefMessage);

          setState(() {
            _isSuccess = true;
            _isWriting = false;
            _status = 'Successfully wrote Business Card to NFC Tag!';
          });
          await NfcManager.instance.stopSession(alertMessage: 'Successfully wrote.');
        } catch (e) {
          setState(() {
            _status = 'Failed to write: ${e.toString()}';
          });
          await NfcManager.instance.stopSession(errorMessage: 'Write failed.');
        }
      },
      onError: (error) async {
        setState(() {
          _status = 'Error during NFC session: ${error.message}';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF16201D) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Write to NFC',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 24),
            _buildNfcIcon(),
            const SizedBox(height: 24),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess
                      ? AppColors.primaryGreen
                      : (isDark ? Colors.white12 : Colors.black12),
                  foregroundColor: _isSuccess
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textBlack),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  _isSuccess ? 'Done' : 'Cancel',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcIcon() {
    if (_isSuccess) {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle_rounded, size: 48, color: AppColors.primaryGreen),
      );
    }
    if (_isUnsupported) {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.nfc_rounded, size: 48, color: Colors.red),
      );
    }
    return SizedBox(
      height: 80,
      width: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isWriting)
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
                strokeWidth: 3,
              ),
            ),
          Icon(Icons.nfc_rounded, size: 40, color: AppColors.primaryGreen),
        ],
      ),
    );
  }
}
