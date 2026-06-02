import 'dart:math';

const int kCols = 9;
const int kRows = 11;
const double kTileSize = 40.0;
const double kHudHeight = 50.0;

enum TileType { floor, hardWall, softWall }

class Grid {
  final List<List<TileType>> _tiles;

  Grid._(this._tiles);

  factory Grid.generate({int? seed}) {
    final rng = Random(seed);
    final tiles = List.generate(
      kRows,
      (row) => List.generate(kCols, (col) {
        if (col.isEven && row.isEven) return TileType.hardWall;
        return TileType.floor;
      }),
    );

    for (var row = 0; row < kRows; row++) {
      for (var col = 0; col < kCols; col++) {
        if (tiles[row][col] != TileType.floor) continue;
        if (col <= 1 && row <= 1) continue; // keep player spawn area clear
        if (rng.nextDouble() < 0.6) tiles[row][col] = TileType.softWall;
      }
    }

    return Grid._(tiles);
  }

  TileType at(int col, int row) => _tiles[row][col];

  void setTile(int col, int row, TileType type) => _tiles[row][col] = type;

  bool isWalkable(int col, int row) {
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return false;
    return _tiles[row][col] == TileType.floor;
  }
}
