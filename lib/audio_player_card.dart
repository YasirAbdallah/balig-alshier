// import 'package:arabic_app/voice_wave.dart'; // Assuming VoiceWaveformPainter is in this file
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'dart:async';

// class VoiceCard extends StatefulWidget {
//   final String audioSource;
//   const VoiceCard({super.key, required this.audioSource});

//   @override
//   VoiceCardState createState() => VoiceCardState();
// }

// class VoiceCardState extends State<VoiceCard> {
//   late final AudioPlayer _audioPlayer;
//   late final ScrollController _scrollController;
//   bool isPlaying = false;
//   bool isLoading = false;
//   Duration _currentPosition = Duration.zero;
//   Duration _totalDuration = Duration.zero;
//   List<double> waveData = [];

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//     _scrollController = ScrollController();
//     _initializeAudio();
//     _audioPlayer.positionStream.listen((position) {
//       setState(() {
//         _currentPosition = position;
//         _scrollController.jumpTo(
//           _currentPosition.inMilliseconds /
//               (_totalDuration.inMilliseconds > 0
//                   ? _totalDuration.inMilliseconds
//                   : 1) *
//               _scrollController.position.maxScrollExtent,
//         );
//       });
//     });
//     _audioPlayer.durationStream.listen((duration) {
//       setState(() {
//         _totalDuration = duration ?? Duration.zero;
//       });
//     });
//     _audioPlayer.playerStateStream.listen((state) {
//       if (state.processingState == ProcessingState.completed) {
//         _audioCompleted();
//       }
//     });
//     // Simulate wave data for demo purposes
//     waveData = List<double>.generate(200, (index) => (index % 20) / 10);
//   }

//   Future<void> _initializeAudio() async {
//     setState(() {
//       isLoading = true;
//     });
//     try {
//       if (widget.audioSource.startsWith('http://') ||
//           widget.audioSource.startsWith('https://')) {
//         await _audioPlayer.setUrl(widget.audioSource);
//       } else {
//         await _audioPlayer.setFilePath(widget.audioSource);
//       }
//       setState(() {
//         _currentPosition = Duration.zero;
//         _totalDuration = _audioPlayer.duration ?? Duration.zero;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _toggleAudio() async {
//       setState(() {
//       isPlaying = !isPlaying;
//     });
//     if (!isPlaying) {
//       await _audioPlayer.pause();
//     } else {
//       await _audioPlayer.play();
//     }
  
//   }

//   void _audioCompleted() {
//     setState(() {
//       isPlaying = false;
//     });
//     _audioPlayer.seek(Duration.zero);
//   }

//   Future<void> _rewind() async {
//     final newPosition = _currentPosition - Duration(seconds: 10);
//     await _audioPlayer
//         .seek(newPosition < Duration.zero ? Duration.zero : newPosition);
//   }

//   Future<void> _forward() async {
//     final newPosition = _currentPosition + Duration(seconds: 10);
//     if (_totalDuration.inSeconds > 0) {
//       await _audioPlayer
//           .seek(newPosition > _totalDuration ? _totalDuration : newPosition);
//     }
//   }

//   void _onScroll() {
//     if (_scrollController.hasClients) {
//       final newPosition = _scrollController.offset /
//           _scrollController.position.maxScrollExtent *
//           _totalDuration.inMilliseconds;
//       _audioPlayer.seek(Duration(milliseconds: newPosition.round()));
//     }
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(1.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       child: Container(
//         child: Padding(
//           padding: EdgeInsets.all(8.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   Card(
//                     margin: EdgeInsets.all(10),
//                     child: isLoading
//                         ? CircularProgressIndicator()
//                         : IconButton(
//                             icon: Icon(
//                               isPlaying ? Icons.pause : Icons.play_arrow,
//                               size: 35.0,
//                               color: Colors.orangeAccent,
//                             ),
//                             onPressed: _toggleAudio,
//                           ),
//                   ),
//                   Expanded(
//                     child: GestureDetector(
//                       onHorizontalDragUpdate: (details) {
//                         _scrollController.jumpTo(
//                           _scrollController.position.pixels + details.delta.dx,
//                         );
//                         _onScroll();
//                       },
//                       child: Container(
//                         height: 35,
//                         decoration: BoxDecoration(
//                           color:
//                               Colors.white, // Background color for the waveform
//                           borderRadius:
//                               BorderRadius.circular(15.0), // Rounded corners
//                         ),
//                         clipBehavior: Clip
//                             .antiAlias, // Ensure rounded corners are respected
//                         child: ListView.builder(
//                           controller: _scrollController,
//                           scrollDirection: Axis.horizontal,
//                           itemCount: waveData.length,
//                           itemBuilder: (context, index) {
//                             return CustomPaint(
//                               size: Size(3, 45),
//                               painter: VoiceWaveformPainter(
//                                 progress: _currentPosition.inMilliseconds /
//                                     (_totalDuration.inMilliseconds > 0
//                                         ? _totalDuration.inMilliseconds
//                                         : 1),
//                                 waveData:
//                                     waveData.sublist(index, waveData.length),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "${_currentPosition.inMinutes}:${(_currentPosition.inSeconds % 60).toString().padLeft(2, '0')}",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                   Expanded(
//                     // Use Expanded to make Slider take more space
//                     child: Slider(
//                       activeColor: Colors.orangeAccent,
//                       value: _currentPosition.inSeconds.toDouble(),
//                       min: 0.0,
//                       max: _totalDuration.inSeconds.toDouble(),
//                       onChanged: (value) {
//                         setState(() {
//                           _audioPlayer.seek(Duration(seconds: value.toInt()));
//                         });
//                       },
//                     ),
//                   ),
//                   Text(
//                     "${_totalDuration.inMinutes}:${(_totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
