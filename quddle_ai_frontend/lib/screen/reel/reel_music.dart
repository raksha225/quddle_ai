// import 'package:flutter/material.dart';
// import '../../utils/routes.dart';

// class MusicScreen extends StatelessWidget {
//   const MusicScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             SliverToBoxAdapter( 
//               child: Column(
//                 children: [
//                   // --- Top Bar ---
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     child: Row(
//                       children: [
//                         GestureDetector(
//                           onTap: () => AppRoutes.goBack(context),
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.arrow_back,
//                               color: Colors.black,
//                               size: 20,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         const Expanded(
//                           child: Text(
//                             "Music",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                         const SizedBox(width: 40), // Balance the back button
//                       ],
//                     ),
//                   ),

//                   // --- Music Content ---
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
//                     child: Row(
//                       children: [
//                         // Music icon (left aligned)
//                         Container(
//                           width: 100,
//                           height:  100,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[800],
//                             borderRadius: BorderRadius.circular(4),
//                             shape: BoxShape.rectangle,
//                             border: Border.all(
                              
//                               color: Colors.grey[600]!,
//                               width: 2,
//                             ),
//                           ),
//                           child: const Icon(
//                             Icons.music_note,
//                             color: Colors.white,
//                             size: 30,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
                        
//                         // Text content (aligned with icon)
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 "Song not found",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 "No music detected in this video",
//                                 style: TextStyle(
//                                   color: Colors.grey[400],
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
