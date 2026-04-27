enum FontFamilies { openSans, asimovian, atkinson, caveat }

extension FontFamiliesMethods on FontFamilies {
  String get key {
    switch (this) {
      case FontFamilies.openSans:
        return 'OpenSans';
      case FontFamilies.asimovian:
        return 'Asimovian';
      case FontFamilies.atkinson:
        return 'Atkinson';
      case FontFamilies.caveat:
        return 'Caveat';
    }
  }
}
