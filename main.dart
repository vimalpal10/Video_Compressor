import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(VideoCompressorApp());
}

class VideoCompressorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Compressor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedVideoPath;
  String? _selectedVideoName;
  String? _compressedVideoPath;
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  String _statusMessage = '🎬 वीडियो चुनें';
  
  int? _originalSize;
  int? _compressedSize;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    // Listen to compression progress
    VideoCompress.compressProgress$.subscribe((progress) {
      if (mounted) {
        setState(() {
          _compressionProgress = progress;
        });
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File videoFile = File(result.files.single.path!);
        
        setState(() {
          _selectedVideoPath = result.files.single.path!;
          _selectedVideoName = result.files.single.name;
          _originalSize = videoFile.lengthSync();
          _statusMessage = '✅ वीडियो चुन लिया गया!\n\n'
              '📁 ${result.files.single.name}\n'
              '📊 Size: ${_formatFileSize(_originalSize!)}';
          _compressedVideoPath = null;
          _compressedSize = null;
        });
        
        _showMessage('वीडियो successfully select हो गया!', Colors.green);
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
      print('Error picking video: $e');
    }
  }

  Future<void> _compressVideo() async {
    if (_selectedVideoPath == null) {
      _showMessage('⚠️ पहले वीडियो चुनें!', Colors.orange);
      return;
    }

    setState(() {
      _isCompressing = true;
      _statusMessage = '⏳ वीडियो compress हो रहा है...\n\nकृपया प्रतीक्षा करें\nयह कुछ समय ले सकता है';
      _compressionProgress = 0.0;
    });

    try {
      final info = await VideoCompress.compressVideo(
        _selectedVideoPath!,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && mounted) {
        setState(() {
          _compressedVideoPath = info.path;
          _compressedSize = info.filesize;
          _isCompressing = false;
          
          if (_originalSize != null && _compressedSize != null) {
            double savingsPercent = ((_originalSize! - _compressedSize!) / _originalSize!) * 100;
            int savedBytes = _originalSize! - _compressedSize!;
            
            _statusMessage = '🎉 सफलता! Video Compressed!\n\n'
                '📊 Original Size: ${_formatFileSize(_originalSize!)}\n'
                '📉 Compressed Size: ${_formatFileSize(_compressedSize!)}\n'
                '💾 Space बचा: ${_formatFileSize(savedBytes)}\n'
                '📈 ${savingsPercent.toStringAsFixed(1)}% कम हुआ!\n\n'
                '📁 Saved at:\n$_compressedVideoPath';
          }
        });

        _showMessage('✅ Video successfully compress हो गया!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressing = false;
          _statusMessage = '❌ Compression में गलती आ गई\n\nError: $e';
        });
      }
      _showMessage('❌ Compression failed: $e', Colors.red);
      print('Compression error: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎬 Video Compressor'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                
                // App Icon
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.video_library_rounded,
                    size: 80,
                    color: Colors.blue.shade700,
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        if (_selectedVideoPath != null && !_isCompressing && _compressedSize == null) ...[
                          SizedBox(height: 15),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 40,
                          ),
                        ],
                        if (_compressedSize != null) ...[
                          SizedBox(height: 15),
                          Icon(
                            Icons.celebration,
                            color: Colors.green,
                            size: 50,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Select Video Button
                ElevatedButton.icon(
                  onPressed: _isCompressing ? null : _pickVideo,
                  icon: Icon(Icons.folder_open_rounded, size: 24),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      '📂 वीडियो चुनें',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                ),
                
                SizedBox(height: 15),
                
                // Compress Button
                ElevatedButton.icon(
                  onPressed: (_isCompressing || _selectedVideoPath == null)
                      ? null
                      : _compressVideo,
                  icon: Icon(Icons.compress_rounded, size: 24),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      '🚀 Compress करें',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Progress Indicator
                if (_isCompressing) ...[
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          SizedBox(height: 20),
                          Text(
                            '⏳ Processing...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 15),
                          LinearProgressIndicator(
                            value: _compressionProgress / 100,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '${_compressionProgress.toStringAsFixed(0)}% पूरा हुआ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                
                // Instructions Card
                Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              'कैसे इस्तेमाल करें',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        _buildInstructionStep('1️⃣', '"वीडियो चुनें" पर टैप करें'),
                        _buildInstructionStep('2️⃣', 'Gallery से अपना वीडियो select करें'),
                        _buildInstructionStep('3️⃣', '"Compress करें" पर टैप करें'),
                        _buildInstructionStep('4️⃣', 'Wait करें, compression होने तक'),
                        _buildInstructionStep('5️⃣', 'Done! Compressed video ready! 🎉'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Features Info
                Card(
                  color: Colors.green.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Features:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          '✅ Original video safe रहेगा\n'
                          '✅ High quality compression\n'
                          '✅ Audio preserved\n'
                          '✅ 50-70% space बचाएं',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    VideoCompress.dispose();
    super.dispose();
  }
}