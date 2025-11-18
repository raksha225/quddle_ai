import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/reels_service.dart';
import '../../bloc/Profile/profile_bloc.dart';
import '../../bloc/Profile/profile_event.dart';
import '../../bloc/Profile/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  final bool loading;
  final List<dynamic> reels;
  final void Function(Map<String, dynamic> reel)? onSelect;
  final void Function(String reelId, bool isLiked, int likeCount)? onLikeChanged;

  const ProfileScreen({
    super.key,
    required this.loading,
    required this.reels,
    this.onSelect,
    this.onLikeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<dynamic> _reels; // local, mutable copy

  @override
  void initState() {
    super.initState();
    _reels = List<dynamic>.from(widget.reels);
    _loadReels();
    // Load profile using BLoC
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent provides a new reels list, sync local copy
    if (!identical(oldWidget.reels, widget.reels)) {
      _reels = List<dynamic>.from(widget.reels);
    }
  }

  Future<void> _loadReels() async {
    try {
      List<dynamic> _myReelsResponse = await ReelsService.listMyReels();

      List<dynamic> _myReels = [];

      const oldDomain = 'quddle-ai-reel-upload-process-videos.s3.ap-south-1.amazonaws.com';
      const newDomain = 'db1e7qdc0cu2m.cloudfront.net';

      for (final reel in _myReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] = updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _myReels.add(updatedReel);
      }

      if (!mounted) return;

      setState(() {
        _reels = _myReels;
      });
    } catch (e) {
      if (!mounted) return;
      print("Can't load reels at Home!");
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: widget.loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // --- Top Bar ---
                        BlocBuilder<ProfileBloc, ProfileState>(
                          builder: (context, profileState) {
                            String displayName = 'User';
                            bool isLoadingProfile = false;

                            if (profileState is ProfileLoading) {
                              isLoadingProfile = true;
                            } else if (profileState is ProfileLoaded) {
                              displayName = profileState.user.name;
                            } else if (profileState is ProfileError) {
                              displayName = 'User';
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isLoadingProfile ? 'Loading...' : displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // --- Profile Stats ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Text('0',
                                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      Text('Posts',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          )),
                                    ],
                                  ),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: Colors.grey, size: 40),
                                  ),
                                  Column(
                                    children: [
                                      const Text('0',
                                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      Text('Followers',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Reels Grid ---
                  _reels.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No reels yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final reel = _reels[index] as Map<String, dynamic>;
                                final thumbnailUrl = reel['thumbnail_url'] as String?;
                                return GestureDetector(
                                  onTap: () => widget.onSelect?.call(reel),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          color: Colors.grey[800],
                                          child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                              ? Image.network(
                                                  thumbnailUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  loadingBuilder: (context, child, progress) {
                                                    if (progress == null) return child;
                                                    return const Center(
                                                      child: CircularProgressIndicator(color: Colors.white),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white54,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Center(
                                                  child: Text(
                                                    'No Thumbnail',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: Colors.grey[900],
                                                title: const Text('Delete reel', style: TextStyle(color: Colors.white)),
                                                content: const Text('Are you sure you want to delete this reel?',
                                                    style: TextStyle(color: Colors.white70)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm != true) return;

                                            final id = (reel['id'] ?? '').toString();
                                            final ok = await ReelsService.deleteReel(id);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(ok ? 'Reel deleted' : 'Failed to delete reel'),
                                              ),
                                            );
                                            if (ok) {
                                              setState(() {
                                                _reels.removeWhere((e) => (e['id'] ?? '').toString() == id);
                                              });
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(Icons.delete, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: _reels.length,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                              childAspectRatio: 9 / 16,
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
