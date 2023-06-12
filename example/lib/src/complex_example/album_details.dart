import 'package:example/src/complex_example/data.dart';
import 'package:example/src/complex_example/cover_art.dart';
import 'package:example/src/complex_example/slide_in_out_app_bar.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void showAlbumDetailsDialog(BuildContext context, int index) {
  Navigator.of(context).push(
    ModalExprollableRouteBuilder(
      pageBuilder: (_, __, ___) => AlbumDetailsDialog(index: index),
    ),
  );
}

class AlbumDetailsDialog extends ConsumerStatefulWidget {
  const AlbumDetailsDialog({
    super.key,
    required this.index,
  });

  final int index;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AlbumDetailsDialogState();
}

class _AlbumDetailsDialogState extends ConsumerState<AlbumDetailsDialog> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = ExprollablePageController(
      initialPage: widget.index,
      viewportConfiguration: ViewportConfiguration(
        overshootEffect: true,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(vulfRecordsProvider).when(
          loading: () => Container(),
          error: (error, stackTrace) => const Placeholder(),
          data: (albums) {
            return ExprollablePageView(
              controller: controller,
              itemCount: albums.length,
              itemBuilder: (context, page) {
                return PageGutter(
                  gutterWidth: 8,
                  child: AlbumDetailsContainer(
                    album: albums[page],
                  ),
                );
              },
            );
          },
        );
  }
}

class AlbumDetailsContainer extends StatelessWidget {
  const AlbumDetailsContainer({
    super.key,
    required this.album,
  });

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AlbumDetails(
              album: album,
            ),
          ),
          SlideInOutAppBar(
            title: album.title,
            thresholdScrollOffset: 400,
          ),
          const Positioned(
            top: 0.0,
            right: 0.0,
            child: CloseButton(),
          ),
        ],
      ),
    );
  }
}

class CloseButton extends StatelessWidget {
  const CloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePagePadding(
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.cancel,
          color: Colors.black45,
        ),
      ),
    );
  }
}

class AlbumDetails extends StatelessWidget {
  const AlbumDetails({
    super.key,
    required this.album,
  });

  final Album album;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: PageContentScrollController.of(context),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 52, 32, 32),
          sliver: SliverToBoxAdapter(
            child: CoverArt(url: album.coverArtUrl(large: true)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(18),
          sliver: SliverToBoxAdapter(
            child: AlbumSummary(album: album),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.all(18),
          sliver: SliverToBoxAdapter(
            child: AlbumActions(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          sliver: SliverToBoxAdapter(
            child: ListTile(
              title: const Text('Tracks'),
              tileColor: Colors.grey[200],
            ),
          ),
        ),
        AlbumTracklist(album: album),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: Center(
              child: Icon(
                Icons.flutter_dash_outlined,
                color: Colors.black12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AlbumSummary extends StatelessWidget {
  const AlbumSummary({
    super.key,
    required this.album,
  });

  final Album album;

  @override
  Widget build(BuildContext context) {
    final typo = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          album.title,
          textAlign: TextAlign.center,
          style: typo.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          album.artist,
          textAlign: TextAlign.center,
          style: typo.titleLarge,
        ),
      ],
    );
  }
}

class AlbumActions extends StatelessWidget {
  const AlbumActions({super.key});

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 58.0;
    final filledStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black,
      minimumSize: const Size.fromHeight(buttonHeight),
    );
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(buttonHeight),
      shape: const StadiumBorder(),
    );

    return Column(
      children: [
        FilledButton(
          onPressed: () {},
          style: filledStyle,
          child: const Text('Purchase | \$12'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Wish List"),
                  style: outlinedStyle,
                  onPressed: () {},
                ),
              ),
              const SizedBox(
                height: buttonHeight,
                width: 12,
              ),
              Flexible(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.music_note),
                  label: const Text("Play"),
                  style: outlinedStyle,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AlbumTracklist extends ConsumerWidget {
  const AlbumTracklist({
    super.key,
    required this.album,
  });

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(tracklistProvider(album)).when(
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, stackTrace) {
            return const SliverToBoxAdapter(
              child: ListTile(
                title: Text('Failed to fetch the tracks.'),
              ),
            );
          },
          data: (tracks) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: tracks.length,
                (context, index) {
                  return AlbumTrackListTile(
                    track: tracks[index],
                  );
                },
              ),
            );
          },
        );
  }
}

class AlbumTrackListTile extends StatelessWidget {
  const AlbumTrackListTile({
    super.key,
    required this.track,
  });

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {},
            icon: Icons.favorite_border,
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white60,
          )
        ],
      ),
      child: ListTile(
        onTap: () {},
        trailing: const Icon(Icons.more_vert),
        title: Text(track.title),
        subtitle: Text(track.displayDuration),
      ),
    );
  }
}
