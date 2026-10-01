import 'dart:async';

import 'package:chess/app/theme/app_motion.dart';
import 'package:chess/chess_engine/chess_engine.dart';
import 'package:chess/features/game/presentation/board/chess_board_host.dart';
import 'package:chess/features/game/presentation/controllers/offline_game_controller.dart';
import 'package:chess/features/game/presentation/theme/board_theme_palette.dart';
import 'package:chess/features/game/presentation/widgets/chess_piece_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Interactive 8×8 chess board with move highlights and piece animations.
class ChessBoardWidget<C extends GetxController> extends StatefulWidget {
  const ChessBoardWidget({super.key});

  @override
  State<ChessBoardWidget<C>> createState() => _ChessBoardWidgetState<C>();
}

class _ChessBoardWidgetState<C extends GetxController>
    extends State<ChessBoardWidget<C>> with SingleTickerProviderStateMixin {
  ChessMove? _animatingMove;
  ChessMove? _lastAnimatedMove;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(precacheChessPieces(context));
      }
    });
  }

  void _configureAnimation(BuildContext context) {
    final duration = AppMotion.reducedMotion(context)
        ? Duration.zero
        : AppMotion.duration(context, AppMotion.fast);
    _controller.duration = duration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playMoveAnimation(ChessMove move) {
    setState(() => _animatingMove = move);
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _animatingMove = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    _configureAnimation(context);
    return GetBuilder<C>(
      id: _boardUpdateId,
      builder: (controller) {
        final host = controller as ChessBoardHost;
        final lastMove = host.lastMove;
        if (lastMove != null && lastMove != _lastAnimatedMove) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                lastMove != host.lastMove ||
                lastMove == _lastAnimatedMove) {
              return;
            }
            _lastAnimatedMove = lastMove;
            if (AppMotion.reducedMotion(context)) {
              setState(() => _animatingMove = null);
            } else {
              _playMoveAnimation(lastMove);
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            final squareSize = size / 8;

            return RepaintBoundary(
              child: SizedBox(
                width: size,
                height: size,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        for (var rank = 0; rank < 8; rank++)
                          for (var file = 0; file < 8; file++)
                            _SquareTile(
                              square: _displayToSquare(
                                file,
                                rank,
                                host.boardFlipped,
                              ),
                              displayFile: file,
                              displayRank: rank,
                              squareSize: squareSize,
                              host: host,
                            ),
                        ..._buildPieces(host, squareSize),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const _boardUpdateId = 'board';

  List<Widget> _buildPieces(ChessBoardHost host, double size) {
    final pieces = <Widget>[];
    final anim = _animatingMove;

    for (var i = 0; i < 64; i++) {
      final square = Square.fromIndex(i)!;
      final piece = host.position.pieceAt(square);
      if (piece == null) continue;

      if (anim != null && square == anim.from) continue;

      var displaySquare = square;
      if (anim != null && square == anim.to) {
        displaySquare = anim.from;
      }

      final display = _squareToDisplay(
        displaySquare,
        host.boardFlipped,
      );

      var offset = Offset(display.file * size, display.rank * size);

      if (anim != null && square == anim.to) {
        final fromDisplay = _squareToDisplay(anim.from, host.boardFlipped);
        final toDisplay = _squareToDisplay(anim.to, host.boardFlipped);
        final fromOffset = Offset(fromDisplay.file * size, fromDisplay.rank * size);
        final toOffset = Offset(toDisplay.file * size, toDisplay.rank * size);
        offset = Offset.lerp(fromOffset, toOffset, _animation.value)!;
      }

      pieces.add(
        AnimatedPositioned(
          // Position is driven manually via Offset.lerp in the AnimatedBuilder,
          // so the implicit animation is disabled to avoid double-animating.
          duration: Duration.zero,
          left: offset.dx,
          top: offset.dy,
          width: size,
          height: size,
          child: IgnorePointer(
            child: ChessPieceWidget(piece: piece, size: size),
          ),
        ),
      );
    }

    return pieces;
  }

  Square _displayToSquare(int file, int rank, bool flipped) {
    if (!flipped) {
      return Square.fromIndex(file + (7 - rank) * 8)!;
    }
    return Square.fromIndex((7 - file) + rank * 8)!;
  }

  ({int file, int rank}) _squareToDisplay(Square square, bool flipped) {
    if (!flipped) {
      return (file: square.file, rank: 7 - square.rank);
    }
    return (file: 7 - square.file, rank: square.rank);
  }
}

class _SquareTile extends StatelessWidget {
  const _SquareTile({
    required this.square,
    required this.displayFile,
    required this.displayRank,
    required this.squareSize,
    required this.host,
  });

  final Square square;
  final int displayFile;
  final int displayRank;
  final double squareSize;
  final ChessBoardHost host;

  @override
  Widget build(BuildContext context) {
    final isLight = (square.file + square.rank).isEven;
    final isHighlighted = host.isSquareHighlighted(square);
    final isCheck = host.isSquareInCheck(square);
    final isTarget = host.legalTargets.contains(square);
    final hasPiece = host.position.pieceAt(square) != null;

    final palette = BoardThemePalette.colors(host.boardTheme);
    final baseColor = isLight ? palette.$1 : palette.$2;

    return Positioned(
      left: displayFile * squareSize,
      top: displayRank * squareSize,
      width: squareSize,
      height: squareSize,
      child: GestureDetector(
        onTap: () => host.onSquareTap(square),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isCheck
                ? Colors.red.shade400.withValues(alpha: 0.85)
                : isHighlighted
                    ? const Color(0xFFBACA44).withValues(alpha: 0.75)
                    : baseColor,
          ),
          child: isTarget
              ? Center(
                  child: Container(
                    width: hasPiece ? squareSize * 0.85 : squareSize * 0.28,
                    height: hasPiece ? squareSize * 0.85 : squareSize * 0.28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasPiece
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.18),
                      border: hasPiece
                          ? Border.all(color: Colors.black38, width: 3)
                          : null,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Default offline board widget alias.
typedef OfflineChessBoardWidget = ChessBoardWidget<OfflineGameController>;
