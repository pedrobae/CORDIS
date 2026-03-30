import 'package:sqflite/sqflite.dart';

Future<void> insertSections(
  Transaction txn,
  Map<String, int> versionIds,
) async {
  // amazingGraceVersion1Id contents
  await txn.insert('section', {
    'version_id': versionIds['amazing1'],
    'content_code': 'V1',
    'content_type': 'Verso 1',
    'content_text': '''A[G]mazing [G7]Grace, how [C]sweet the [G]sound
That [G]saved a [D]wretch like [G]me
I [G]once was [G7]lost, but [C]now am [G]found
Was [G]blind, but [D]now I [G]see''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['amazing1'],
    'content_code': 'V2',
    'content_type': 'Verso 2',
    'content_text': ''''Twas [G]grace that [G7]taught my [C]heart to [G]fear
And [G]grace my [D]fears re[G]lieved
How [G]precious [G7]did that [C]grace ap[G]pear
The [G]hour I [D]first be[G]lieved''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['amazing1'],
    'content_code': 'V3',
    'content_type': 'Verso 3',
    'content_text': '''Through [G]many [G7]dangers, [C]toils and [G]snares
I [G]have al[D]ready [G]come
'Tis [G]grace hath [G7]brought me [C]safe thus [G]far
And [G]grace will [D]lead me [G]home''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['amazing1'],
    'content_code': 'V4',
    'content_type': 'Verso 4',
    'content_text': '''When [G]we've been [G7]there ten [C]thousand [G]years
Bright [G]shining [D]as the [G]sun
We've [G]no less [G7]days to [C]sing God's [G]praise
Than [G]when we [D]first be[G]gun''',
    'content_color': '#2196F3',
  });

  // amazingGraceMap2Id (transposed D)
  await txn.insert('section', {
    'version_id': versionIds['amazing2'],
    'content_code': 'V1',
    'content_type': 'Verso 1',
    'content_text': '''A[D]mazing [D7]Grace, how [G]sweet the [D]sound
That [D]saved a [A]wretch like [D]me
I [D]once was [D7]lost, but [G]now am [D]found
Was [D]blind, but [A]now I [D]see''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['amazing2'],
    'content_code': 'V3',
    'content_type': 'Verso 3',
    'content_text': '''Through [D]many [D7]dangers, [G]toils and [D]snares
I [D]have al[A]ready [D]come
'Tis [D]grace hath [D7]brought me [G]safe thus [D]far
And [D]grace will [A]lead me [D]home''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['amazing2'],
    'content_code': 'V4',
    'content_type': 'Verso 4',
    'content_text': '''When [D]we've been [D7]there ten [G]thousand [D]years
Bright [D]shining [A]as the [D]sun
We've [D]no less [D7]days to [G]sing God's [D]praise
Than [D]when we [A]first be[D]gun''',
    'content_color': '#2196F3',
  });

  // howGreatMap1Id contents
  await txn.insert('section', {
    'version_id': versionIds['howgreat1'],
    'content_code': 'V1',
    'content_type': 'Verso 1',
    'content_text': '''O [D]Lord my God, when [G]I in awesome [D]wonder
Consider [D]all the [A]worlds Thy hands have [D]made
I see the [D]stars, I [G]hear the rolling [D]thunder
Thy power through[D]out the [A]universe dis[D]played''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['howgreat1'],
    'content_code': 'C',
    'content_type': 'Refrão',
    'content_text': '''Then sings my [D]soul, my [G]Saviour God, to [D]Thee
How great Thou [A]art, how great Thou [D]art
Then sings my [D]soul, my [G]Saviour God, to [D]Thee
How great Thou [A]art, how great Thou [D]art''',
    'content_color': '#F44336',
  });

  await txn.insert('section', {
    'version_id': versionIds['howgreat1'],
    'content_code': 'V2',
    'content_type': 'Verso 2',
    'content_text':
        '''When through the [D]woods and [G]forest glades I [D]wander
And hear the [D]birds sing [A]sweetly in the [D]trees
When I look [D]down from [G]lofty mountain [D]grandeur
And hear the [D]brook and [A]feel the gentle [D]breeze''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['howgreat1'],
    'content_code': 'V3',
    'content_type': 'Verso 3',
    'content_text': '''And when I [D]think that [G]God, His Son not [D]sparing
Sent Him to [D]die, I [A]scarce can take it [D]in
That on the [D]cross, my [G]burden gladly [D]bearing
He bled and [D]died to [A]take away my [D]sin''',
    'content_color': '#2196F3',
  });

  await txn.insert('section', {
    'version_id': versionIds['howgreat1'],
    'content_code': 'V4',
    'content_type': 'Verso 4',
    'content_text': '''When Christ shall [D]come with [G]shout of acclamation
And take me [D]home, what [A]joy shall fill my [D]heart
Then I shall [D]bow in [G]humble adora[D]tion
And there pro[D]claim, my [A]God, how great Thou [D]art''',
    'content_color': '#2196F3',
  });
}
