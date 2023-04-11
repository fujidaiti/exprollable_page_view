import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

part 'data.freezed.dart';

const _vulfpeckMBID = '7d0e8067-10b9-4069-95dc-1110a0fbb877';

const _userAgentString =
    'ExprollablePageViewExample/0.0.1 (https://github.com/fujidaiti/exprollable_page_view)';

Future<http.Response> _get(Uri url) => http.get(
      url,
      headers: {
        'User-Agent': _userAgentString,
        'Accept': 'application/json',
      },
    );

Future<List<Album>> _fetchAllReleases(String artistMBID) async {
  final response = await _get(Uri.parse(
    'https://musicbrainz.org/ws/2/artist/$artistMBID/?inc=releases&fmt=json',
  ));
  if (response.statusCode == 200) {
    return _parseReleases(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch music data.');
  }
}

String _coverArtUrl(String mbid, int size) =>
    'https://coverartarchive.org/release/$mbid/front-$size.jpg';

Future<List<Track>> _fetchTracklist(Album record) async {
  final response = await _get(Uri.parse(
    'https://musicbrainz.org/ws/2/release/${record.mbid}/?inc=recordings&fmt=json',
  ));
  if (response.statusCode == 200) {
    return _parseTracklist(jsonDecode(response.body));
  } else {
    throw Exception(
      'Failed to fetch the tracklist of ${record.title}(${record.mbid}).',
    );
  }
}

List<Album> _parseReleases(dynamic data) {
  final artist = data['name'];
  final releases = data['releases'];
  assert(releases is List);
  return (releases as List).map((r) => _parseAlbum(r, artist)).toList();
}

List<Track> _parseTracklist(dynamic data) {
  final tracks = data['media'][0]['tracks'];
  assert(tracks is List);
  return (tracks as List).map(_parseTrack).toList();
}

Album _parseAlbum(dynamic data, String artist) {
  return Album(
    mbid: data['id'],
    title: data['title'],
    artist: artist,
    releaseDate: data['date'],
  );
}

Track _parseTrack(dynamic data) {
  return Track(
    title: data['title'],
    duration: data['length'],
  );
}

@freezed
class Album with _$Album {
  const Album._();
  const factory Album({
    required String mbid,
    required String artist,
    required String title,
    required String releaseDate,
  }) = _Album;

  String coverArtUrl({bool large = false}) =>
      _coverArtUrl(mbid, large ? 500 : 250);
}

@freezed
class Track with _$Track {
  const Track._();
  const factory Track({
    required String title,
    required int duration,
  }) = _Track;

  String get displayDuration {
    final d = Duration(milliseconds: duration);
    final mins = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

final vulfRecordsProvider = FutureProvider.autoDispose(
  (ref) => _fetchAllReleases(_vulfpeckMBID),
);

final tracklistProvider = FutureProvider.family
    .autoDispose<List<Track>, Album>(
        (ref, record) => _fetchTracklist(record));
