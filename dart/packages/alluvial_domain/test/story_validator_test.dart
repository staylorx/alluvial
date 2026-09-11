import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

const codec = StoryDocumentCodec();
const validator = StoryValidator();

/// A clean braid: six beats, two strands that part in the middle.
Map<String, Object?> cleanDocument() => <String, Object?>{
  'slug': 'a-clean',
  'title': 'A Clean Story',
  'order': ['lea', 'sam'],
  'chars': <Map<String, Object?>>[
    {'id': 'lea', 'name': 'Lea', 'width': 32, 'colour': '#1b57c4'},
    {'id': 'sam', 'name': 'Sam', 'width': 30, 'colour': '#d0316a'},
  ],
  'beats': <Map<String, Object?>>[
    for (var n = 1; n <= 6; n++)
      {
        'name': 'BEAT $n',
        'loc': '≈ $n min',
        'cap': ['first line of beat $n', 'second line of beat $n'],
        'clusters': n == 4
            ? [
                ['lea'],
                ['sam'],
              ]
            : [
                ['lea', 'sam'],
              ],
      },
  ],
};

Story decode(Map<String, Object?> document) =>
    codec.decode(document).getRight().toNullable()!;

List<String> messages(List<ValidationFinding> findings) =>
    findings.map((finding) => finding.describe).toList();

void main() {
  group('StoryValidator — a clean story', () {
    test('Given a valid braid, when validated, then nothing is reported', () {
      validator.validate(decode(cleanDocument())).should.beEmpty();
    });
  });

  group('StoryValidator — structural limits', () {
    test(
      'Given fewer beats than a braid holds, when validated, then the count is reported',
      () {
        final document = cleanDocument();
        document['beats'] = (document['beats']! as List).take(2).toList();

        final findings = validator.validate(decode(document));

        messages(
          findings,
        ).should.contain('beats: 2 beats — a braid holds 6 to 13');
      },
    );

    test(
      'Given more lanes than a braid holds, when validated, then the count is reported',
      () {
        final document = cleanDocument();
        document['chars'] = [
          for (var n = 0; n < 9; n++)
            {'id': 'c$n', 'name': 'C$n', 'width': 20, 'colour': '#6e9078'},
        ];
        document['order'] = [for (var n = 0; n < 9; n++) 'c$n'];

        final findings = validator.validate(decode(document));

        messages(
          findings,
        ).should.contain('chars: 9 lanes — a braid holds 2 to 8');
      },
    );

    test(
      'Given a caption line past the column width, when validated, then the line is named',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'cap': [List.filled(63, 'x').join(), 'second line'],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'beats[0].cap[0]: 63 characters — a caption line fits 62',
        );
      },
    );

    test(
      'Given a caption with one line, when validated, then the line count is reported',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'cap': ['only one line'],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'beats[0].cap: 1 caption lines — a beat carries exactly 2',
        );
      },
    );

    test(
      'Given a beat with no clusters, when validated, then the empty beat is reported',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
        }..remove('clusters');

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'beats[0]: no clusters — every beat needs who stands in it',
        );
      },
    );

    test(
      'Given a lane order missing a character, when validated, then the omission is reported',
      () {
        final document = cleanDocument();
        document['order'] = ['lea'];

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'order: character "sam" is missing from the lane order',
        );
      },
    );
  });

  group('StoryValidator — content', () {
    test(
      'Given a character in two clusters of one beat, when validated, then the doubling is reported',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'clusters': [
            ['lea'],
            ['lea', 'sam'],
          ],
        };

        final findings = validator.validate(decode(document));

        messages(
          findings,
        ).should.contain('beats[0].clusters: "lea" appears in two clusters');
      },
    );

    test(
      'Given a cluster naming an unknown character, when validated, then the id is named',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'clusters': [
            ['lea', 'nobody'],
          ],
        };

        final findings = validator.validate(decode(document));

        messages(
          findings,
        ).should.contain('beats[0].clusters: unknown character "nobody"');
      },
    );

    test(
      'Given an unknown category, when validated, then it is named with the known set',
      () {
        final document = cleanDocument();
        document['rubric'] = 'romcom-27';
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'cats': ['chemistry'],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'beats[0].cats: unknown category "chemistry" — expected one of '
          'chem, meet, bff, breakup, gesture, ebert',
        );
      },
    );

    test(
      'Given a category on a story that declares no rubric, when validated, then it is reported',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'cats': ['chem'],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'beats[0].cats: a category needs a declared rubric — nothing grades this story',
        );
      },
    );

    test(
      'Given a score with no rubric, when validated, then it is reported',
      () {
        final document = cleanDocument();
        document['score'] = 24;

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'score: a score needs a rubric — nothing grades this story',
        );
      },
    );

    test(
      'Given a rubric the store does not know, when validated, then it is named',
      () {
        final document = cleanDocument();
        document['rubric'] = 'romcom-99';

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          "rubric: 'romcom-99' is not one of romcom-27",
        );
      },
    );

    test(
      'Given a year before cinema, when validated, then it is accepted',
      () {
        final document = cleanDocument();
        document['year'] = 1600;

        final findings = validator.validate(decode(document));

        messages(findings).should.beEmpty();
      },
    );

    test(
      'Given a stub on a beat the character appears in later, when validated, then the exit is reported',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'stubs': ['sam'],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'beats[0].stubs: "sam" exits here but is present in "BEAT 2" later',
        );
      },
    );

    test(
      'Given two leads who never separate, when validated, then it warns rather than fails',
      () {
        final document = cleanDocument();
        (document['beats']! as List)[3] = {
          ...(document['beats']! as List)[3] as Map<String, Object?>,
          'clusters': [
            ['lea', 'sam'],
          ],
        };

        final findings = validator.validate(decode(document));

        findings.length.should.be(1);
        findings.single.isWarning.should.be(true);
        findings.single.describe.should.contain(
          'share a cluster in every beat',
        );
      },
    );

    test(
      'Given a reasoned exemption, when validated, then the separation warning is suppressed',
      () {
        final document = cleanDocument()
          ..['never_separate_ok'] = 'handcuffed together for the whole night';
        (document['beats']! as List)[3] = {
          ...(document['beats']! as List)[3] as Map<String, Object?>,
          'clusters': [
            ['lea', 'sam'],
          ],
        };

        validator.validate(decode(document)).should.beEmpty();
      },
    );
  });

  group('StoryValidator — two clocks', () {
    test(
      'Given two spines that are permutations, when validated, then nothing is reported',
      () {
        final document = <String, Object?>{
          'slug': 'a-chop',
          'title': 'A Chop',
          'threads': {'helen': 'Helen'},
          'scenes': <Map<String, Object?>>[
            for (var n = 1; n <= 6; n++)
              {
                'id': 'scene-$n',
                'label': 'Scene $n',
                'as_screened': n,
                'happened': 7 - n,
                'thread': 'helen',
                'mins': 3,
              },
          ],
        };

        validator.validate(decode(document)).should.beEmpty();
      },
    );

    test(
      'Given a scene with no happened position, when validated, then the missing spine is reported',
      () {
        final document = <String, Object?>{
          'slug': 'a-chop',
          'title': 'A Chop',
          'threads': {'helen': 'Helen'},
          'scenes': <Map<String, Object?>>[
            for (var n = 1; n <= 6; n++)
              {
                'id': 'scene-$n',
                'label': 'Scene $n',
                'as_screened': n,
                if (n != 3) 'happened': 7 - n,
                'thread': 'helen',
                'mins': 3,
              },
          ],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'scenes[2].happened: a scene needs a happened position',
        );
        messages(findings).should.contain(
          'scenes.happened: the real order must be a permutation of 1..N',
        );
      },
    );

    test(
      'Given a thread that is not one of the story threads, when validated, then it is named',
      () {
        final document = <String, Object?>{
          'slug': 'a-chop',
          'title': 'A Chop',
          'threads': {'helen': 'Helen'},
          'scenes': <Map<String, Object?>>[
            for (var n = 1; n <= 6; n++)
              {
                'id': 'scene-$n',
                'label': 'Scene $n',
                'as_screened': n,
                'happened': n,
                'thread': n == 2 ? 'nobody' : 'helen',
                'mins': 3,
              },
          ],
        };

        final findings = validator.validate(decode(document));

        messages(findings).should.contain(
          'scenes[1].thread: thread "nobody" is not one of the story\'s threads',
        );
      },
    );
  });
}
