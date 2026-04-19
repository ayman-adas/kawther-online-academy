import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/error_handler.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/video_player_provider.dart';

class VideoScreen extends StatelessWidget {
  final String videoUrl;
  final String title;

  const VideoScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoPlayerProvider(videoUrl),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Consumer<VideoPlayerProvider>(
          builder: (context, provider, child) {
            if (provider.errorMessage != null) {
              return Center(
                child: Text(
                  AppErrorHandler.getErrorMessage(
                      context, provider.errorMessage!),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (provider.isInitialized && provider.chewieController != null) {
              return Center(
                child: Chewie(controller: provider.chewieController!),
              );
            }

            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          },
        ),
      ),
    );
  }
}
