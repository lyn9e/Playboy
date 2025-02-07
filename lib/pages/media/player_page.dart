import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:playboy/backend/keymap_helper.dart';
import 'package:playboy/backend/utils/l10n_utils.dart';
import 'package:playboy/pages/media/player_menu.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_size/window_size.dart';

import 'package:playboy/backend/models/playitem.dart';
import 'package:playboy/backend/storage.dart';
import 'package:playboy/backend/utils/time_utils.dart';
import 'package:playboy/pages/home.dart';
import 'package:playboy/pages/media/fullscreen_play_page.dart';
import 'package:playboy/widgets/interactive_wrapper.dart';
import 'package:playboy/widgets/player_list.dart';
import 'package:playboy/widgets/image.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
  });

  static FocusNode? fn;

  @override
  PlayerPageState createState() => PlayerPageState();
}

class PlayerPageState extends State<PlayerPage> {
  VideoController controller = AppStorage().controller;

  bool _menuExpanded = false;
  bool _videoMode = !AppStorage().settings.defaultMusicMode;
  int _curPanel = 0;

  @override
  void initState() {
    super.initState();
    PlayerPage.fn = FocusNode();
  }

  @override
  void dispose() {
    if (!AppStorage().settings.playAfterExit) {
      AppStorage().closeMedia();
    }
    super.dispose();
    PlayerPage.fn!.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    late final colorScheme = Theme.of(context).colorScheme;
    late final backgroundColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.04),
      colorScheme.surface,
    );
    // _focusNode.requestFocus();
    PlayerPage.fn!.requestFocus();
    return KeyboardListener(
      autofocus: true,
      focusNode: PlayerPage.fn!,
      onKeyEvent: KeyMapHelper.handleKeyEvent,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildTitlebar(backgroundColor),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    // flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _buildPlayer(colorScheme),
                    ),
                  ),
                  _menuExpanded
                      ? Padding(
                          // flex: 2,
                          padding: const EdgeInsets.only(right: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: _videoMode
                                ? 300
                                : MediaQuery.of(context).size.width * 0.4,
                            child:
                                _buildSidePanel(colorScheme, backgroundColor),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            SizedBox(
              width: _videoMode
                  ? MediaQuery.of(context).size.width - 40
                  : MediaQuery.of(context).size.width - 80,
              height: 25,
              child: Row(
                children: [
                  // Text(
                  //     '${AppStorage().position.inSeconds ~/ 3600}:${(AppStorage().position.inSeconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(AppStorage().position.inSeconds % 60).toString().padLeft(2, '0')}'),
                  SizedBox(
                    width: 60,
                    child: StreamBuilder(
                        stream: AppStorage().playboy.stream.position,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              getProgressString(snapshot.data!),
                              // '${snapshot.data!.inSeconds ~/ 3600}:${(snapshot.data!.inSeconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(snapshot.data!.inSeconds % 60).toString().padLeft(2, '0')}',
                            );
                          } else {
                            return Text(
                              getProgressString(AppStorage().position),
                              // '${AppStorage().position.inSeconds ~/ 3600}:${(AppStorage().position.inSeconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(AppStorage().position.inSeconds % 60).toString().padLeft(2, '0')}',
                            );
                          }
                        }),
                  ),
                  Expanded(child: _buildSeekbar()),
                  Container(
                    alignment: Alignment.centerRight,
                    width: 60,
                    child: Text(
                      getProgressString(AppStorage().duration),
                      // '${AppStorage().duration.inSeconds ~/ 3600}:${(AppStorage().duration.inSeconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(AppStorage().duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    ),
                  )
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: _videoMode ? 50 : 80,
              child: _buildControlbar(colorScheme),
            ),
            const SizedBox(height: 10)
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTitlebar(Color backgroundColor) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: Platform.isMacOS
          ? const SizedBox(width: 60)
          : IconButton(
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                // Navigator.pop(context);
                HomePage.switchView?.call();
              },
            ),
      centerTitle: Platform.isMacOS,
      // titleSpacing: 0,
      toolbarHeight: 40,
      flexibleSpace: Column(
        children: [
          SizedBox(
            height: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUp,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  windowManager.startResizing(ResizeEdge.top);
                },
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                windowManager.startDragging();
              },
            ),
          )
        ],
      ),
      // toolbarHeight: videoMode ? null : 70,
      backgroundColor: backgroundColor,
      scrolledUnderElevation: 0,
      title: _videoMode
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                windowManager.startDragging();
              },
              child: StreamBuilder(
                stream: AppStorage().playboy.stream.playlist,
                builder: (context, snapshot) {
                  return Text(
                    AppStorage().playingTitle,
                    style: const TextStyle(fontSize: 18),
                  );
                },
              ),
            )
          : const SizedBox(),
      actions: [
        IconButton(
          icon: const Icon(Icons.subtitles_outlined),
          onPressed: () {
            if (!_menuExpanded) {
              setState(() {
                _menuExpanded = true;
                _curPanel = 0;
              });
            } else if (_curPanel == 0) {
              setState(() {
                _menuExpanded = false;
              });
            } else {
              setState(() {
                _curPanel = 0;
              });
            }
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.menu,
            weight: 550,
          ),
          onPressed: () {
            if (!_menuExpanded) {
              setState(() {
                _menuExpanded = true;
                _curPanel = 1;
              });
            } else if (_curPanel == 1) {
              setState(() {
                _menuExpanded = false;
              });
            } else {
              setState(() {
                _curPanel = 1;
              });
            }
          },
        ),
        if (!Platform.isMacOS)
          IconButton(
            hoverColor: Colors.transparent,
            iconSize: 20,
            onPressed: () {
              windowManager.minimize();
            },
            icon: const Icon(Icons.minimize),
          ),
        if (!Platform.isMacOS)
          IconButton(
            hoverColor: Colors.transparent,
            iconSize: 20,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
            icon: const Icon(Icons.crop_square),
          ),
        if (!Platform.isMacOS)
          IconButton(
            hoverColor: Colors.transparent,
            iconSize: 20,
            onPressed: () {
              windowManager.close();
            },
            icon: const Icon(Icons.close),
          ),
        if (Platform.isMacOS)
          IconButton(
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.video_library_outlined),
            onPressed: () {
              // Navigator.pop(context);
              HomePage.switchView?.call();
            },
          ),
        const SizedBox(
          width: 10,
        ),
      ],
    );
  }

  Widget _buildPlayer(ColorScheme colorScheme) {
    return MInteractiveWrapper(
      menuController: MenuController(),
      menuChildren: _videoMode ? buildPlayerMenu() : const [],
      onTap: null,
      borderRadius: 25,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _videoMode
              ? ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Video(
                      controller: controller,
                      controls: NoVideoControls,
                      subtitleViewConfiguration:
                          const SubtitleViewConfiguration(
                        style: TextStyle(
                          fontSize: 60,
                          color: Colors.white,
                          shadows: <Shadow>[
                            Shadow(
                              blurRadius: 16,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.only(
                    top: 50,
                    left: 50,
                    right: 50,
                    bottom: 75,
                  ),
                  alignment: Alignment.center,
                  child: StreamBuilder(
                    stream: AppStorage().playboy.stream.playlist,
                    builder: (context, snapshot) {
                      return AspectRatio(
                        aspectRatio: 1,
                        child: AppStorage().playingCover == null
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  color: colorScheme.secondaryContainer,
                                ),
                                // padding: const EdgeInsets.all(30),
                                child: Icon(
                                  Icons.music_note,
                                  color: colorScheme.onSecondaryContainer,
                                  size: 120,
                                ),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  image: DecorationImage(
                                    image: MImageProvider(
                                      url: AppStorage().playingCover!,
                                    ).getImage(),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSeekbar() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: StreamBuilder(
        stream: AppStorage().playboy.stream.position,
        builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
          return Slider(
            max: AppStorage().duration.inMilliseconds.toDouble(),
            value: AppStorage().seeking
                ? AppStorage().seekingPos
                : max(
                    min(
                        snapshot.hasData
                            ? snapshot.data!.inMilliseconds.toDouble()
                            : AppStorage().position.inMilliseconds.toDouble(),
                        AppStorage().duration.inMilliseconds.toDouble()),
                    0),
            onChanged: (value) {
              // player.seek(Duration(milliseconds: value.toInt()));
              setState(() {
                AppStorage().seekingPos = value;
              });
            },
            onChangeStart: (value) {
              setState(() {
                AppStorage().seeking = true;
              });
            },
            onChangeEnd: (value) {
              AppStorage()
                  .playboy
                  .seek(Duration(milliseconds: value.toInt()))
                  .then(
                    (value) => {
                      setState(() {
                        AppStorage().seeking = false;
                      })
                    },
                  );
            },
          );
        },
      ),
    );
  }

  Widget _buildControlbar(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _videoMode ? 16 : 32,
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      AppStorage().playboy.setVolume(0);
                    });
                    AppStorage().settings.volume = 0;
                    AppStorage().saveSettings();
                  },
                  icon: Icon(AppStorage().playboy.state.volume == 0
                      ? Icons.volume_off
                      : Icons.volume_up)),
              SizedBox(
                width: 100,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colorScheme.secondaryContainer,
                    thumbColor: colorScheme.secondary,
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    max: 100,
                    value: AppStorage().playboy.state.volume,
                    onChanged: (value) {
                      setState(() {
                        AppStorage().playboy.setVolume(value);
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {});
                      AppStorage().settings.volume = value;
                      AppStorage().saveSettings();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              AppStorage().shuffle = !AppStorage().shuffle;
              AppStorage().playboy.setShuffle(AppStorage().shuffle);
            });
          },
          icon: AppStorage().shuffle
              ? const Icon(Icons.shuffle_on)
              : const Icon(Icons.shuffle),
        ),
        IconButton(
          onPressed: () {
            if (AppStorage().playboy.state.playlistMode ==
                PlaylistMode.single) {
              AppStorage().playboy.setPlaylistMode(PlaylistMode.none);
            } else {
              AppStorage().playboy.setPlaylistMode(PlaylistMode.single);
            }
            setState(() {});
          },
          icon: AppStorage().playboy.state.playlistMode == PlaylistMode.single
              ? const Icon(Icons.repeat_one_on)
              : const Icon(Icons.repeat_one),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: () {
            AppStorage().playboy.previous();
          },
          icon: const Icon(Icons.skip_previous_outlined),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          iconSize: 32,
          onPressed: () {
            setState(() {
              AppStorage().playboy.playOrPause();
            });
          },
          icon: StreamBuilder(
              stream: AppStorage().playboy.stream.playing,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Icon(
                    snapshot.data!
                        ? Icons.pause_circle_outline
                        : Icons.play_arrow_outlined,
                  );
                } else {
                  return Icon(
                    AppStorage().playing
                        ? Icons.pause_circle_outline
                        : Icons.play_arrow_outlined,
                  );
                }
              }),
        ),
        const SizedBox(
          width: 10,
        ),
        IconButton.filledTonal(
            onPressed: () {
              AppStorage().playboy.next();
            },
            icon: const Icon(Icons.skip_next_outlined)),
        const SizedBox(
          width: 10,
        ),
        IconButton(
          icon: _videoMode
              ? const Icon(Icons.music_note_outlined)
              : const Icon(Icons.music_video_outlined),
          onPressed: () {
            setState(() {
              _videoMode = !_videoMode;
            });
          },
        ),
        IconButton(
            onPressed: !_videoMode
                ? null
                : () async {
                    if (Platform.isWindows &&
                        !await windowManager.isMaximized()) {
                      var info = await getCurrentScreen();
                      if (info != null) {
                        await windowManager.setAsFrameless();
                        await windowManager.setPosition(Offset.zero);
                        await windowManager.setSize(
                          Size(
                            info.frame.width / info.scaleFactor,
                            info.frame.height / info.scaleFactor,
                          ),
                        );
                      }
                    } else {
                      windowManager.setFullScreen(true);
                    }

                    // setState(() {
                    //   _fullScreen = !_fullScreen;
                    // });

                    if (!mounted) return;
                    Navigator.push(
                      context,
                      // MaterialPageRoute(
                      //     builder: (context) => const FullscreenPlayPage()),
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            const FullscreenPlayPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
            icon: const Icon(Icons.fullscreen)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 40,
                width: 110,
                child: DropdownMenu<double>(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: OutlineInputBorder(),
                    isDense: true,
                    constraints: BoxConstraints(maxHeight: 40),
                  ),
                  initialSelection: AppStorage().playboy.state.rate,
                  onSelected: (value) {
                    if (value != null) {
                      AppStorage().playboy.setRate(value);
                      setState(() {});
                    }
                  },
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 0.25, label: '0.25X'),
                    DropdownMenuEntry(value: 0.50, label: '0.50X'),
                    DropdownMenuEntry(value: 0.75, label: '0.75X'),
                    DropdownMenuEntry(value: 1.00, label: '1.00X'),
                    DropdownMenuEntry(value: 1.25, label: '1.25X'),
                    DropdownMenuEntry(value: 1.50, label: '1.50X'),
                    DropdownMenuEntry(value: 1.75, label: '1.75X'),
                    DropdownMenuEntry(value: 2.00, label: '2.00X'),
                    DropdownMenuEntry(value: 4.00, label: '4.00X'),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () async {
                  double? customRate = await showDialog<double>(
                    context: context,
                    builder: (BuildContext context) {
                      TextEditingController controller =
                          TextEditingController();
                      controller.text =
                          AppStorage().playboy.state.rate.toString();
                      return AlertDialog(
                        title: Text('自定义倍速'.l10n),
                        content: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: '输入倍速 (e.g. 1.2)'.l10n),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(null);
                            },
                            child: Text('取消'.l10n),
                          ),
                          TextButton(
                            onPressed: () {
                              double? rate = double.tryParse(controller.text);
                              if (rate != null) {
                                Navigator.of(context).pop(rate);
                              } else {
                                Navigator.of(context).pop(null);
                              }
                            },
                            child: Text('确定'.l10n),
                          ),
                        ],
                      );
                    },
                  );
                  if (customRate != null && customRate > 0) {
                    setState(() {
                      AppStorage().playboy.setRate(customRate);
                      AppStorage().settings.speed = customRate;
                      AppStorage().saveSettings();
                    });
                  }
                },
                icon: Icon(
                  AppStorage().playboy.state.rate == 1
                      ? Icons.flash_off
                      : Icons.flash_on,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _videoMode ? 16 : 32,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel(ColorScheme colorScheme, Color backgroundColor) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(25)),
      child: [
        _buildSubtitlePanel(colorScheme, backgroundColor),
        _buildPlaylistPanel(colorScheme, backgroundColor),
      ][_curPanel],
    );
  }

  Widget _buildPlaylistPanel(ColorScheme colorScheme, Color backgroundColor) {
    return Scaffold(
      backgroundColor: _videoMode ? colorScheme.surface : backgroundColor,
      appBar: AppBar(
        backgroundColor: _videoMode ? colorScheme.surface : backgroundColor,
        automaticallyImplyLeading: false,
        toolbarHeight: 46,
        titleSpacing: _videoMode ? null : 8,
        scrolledUnderElevation: 0,
        title: Text(
          '播放列表',
          style: TextStyle(color: colorScheme.primary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _menuExpanded = false;
              });
            },
            icon: Icon(
              Icons.close,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
        ],
      ),
      body: StreamBuilder(
          stream: AppStorage().playboy.stream.playlist,
          builder: (context, snapshot) {
            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var src = AppStorage().playboy.state.playlist.medias[index].uri;
                return SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            AppStorage().playboy.jump(index);
                          },
                          child: PlayerListCard(
                            info: PlayItem(
                              source: src,
                              cover: null,
                              title: p.basenameWithoutExtension(src),
                            ),
                            isPlaying: index == AppStorage().playingIndex,
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            var len = AppStorage()
                                .playboy
                                .state
                                .playlist
                                .medias
                                .length;
                            if (index == AppStorage().playingIndex) {
                              if (len == 1) {
                                AppStorage().closeMedia();
                              } else if (len - 1 == index) {
                                AppStorage().playboy.previous();
                              } else {
                                AppStorage().playboy.next();
                              }
                            }
                            AppStorage().playboy.remove(index);
                            setState(() {});
                          },
                          icon: const Icon(Icons.close)),
                      const SizedBox(
                        width: 4,
                      ),
                    ],
                  ),
                );
              },
              itemCount: AppStorage().playboy.state.playlist.medias.length,
            );
          }),
    );
  }

  Widget _buildSubtitlePanel(ColorScheme colorScheme, Color backgroundColor) {
    return Scaffold(
      backgroundColor: _videoMode ? colorScheme.surface : backgroundColor,
      appBar: AppBar(
        backgroundColor: _videoMode ? colorScheme.surface : backgroundColor,
        automaticallyImplyLeading: false,
        toolbarHeight: 46,
        titleSpacing: _videoMode ? null : 8,
        scrolledUnderElevation: 0,
        title: Text(
          '歌词',
          style: TextStyle(color: colorScheme.primary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _menuExpanded = false;
              });
            },
            icon: Icon(
              Icons.close,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
        ],
      ),
    );
  }
}
