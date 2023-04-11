import 'package:example/src/complex_example/album_details.dart';
import 'package:example/src/complex_example/cover_art.dart';
import 'package:example/src/complex_example/data.dart';
import 'package:example/src/complex_example/error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlbumList extends ConsumerWidget {
  const AlbumList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(vulfRecordsProvider).when(
          error: (error, _) => ErrorMessage(error: error),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          data: (albums) {
            return ListView.builder(
              itemCount: albums.length,
              itemBuilder: (_, index) => AlbumListTile(
                album: albums[index],
                index: index,
              ),
            );
          },
        );
  }
}

class AlbumListTile extends StatelessWidget {
  const AlbumListTile({
    super.key,
    required this.album,
    required this.index,
  });

  final Album album;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => showAlbumDetailsDialog(context, index),
      title: Text(album.title),
      subtitle: Text('${album.artist} · ${album.releaseDate}'),
      leading: CoverArt(url: album.coverArtUrl()),
    );
  }
}
