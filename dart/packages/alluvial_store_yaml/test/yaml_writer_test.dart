import 'package:alluvial_store_yaml/alluvial_store_yaml.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

String write(Object? document) => writeYamlDocument(document);

void main() {
  group('writeYamlDocument — layout', () {
    test(
      'Given a nested mapping, when written, then a sequence sits at its key and a mapping indents',
      () {
        final text = write({
          'beats': [
            {
              'name': 'THE DELI',
              'clusters': [
                ['harry', 'sally'],
              ],
            },
          ],
        });

        text.should.be(
          'beats:\n- name: THE DELI\n  clusters:\n  - - harry\n    - sally\n',
        );
      },
    );

    test('Given an empty list, when written, then it stays on one line', () {
      write({'cats': <Object?>[]}).should.be('cats: []\n');
    });

    test(
      'Given a store-level document, when written, then the canonical keys lead',
      () {
        final text = writeYamlDocument({
          'slug': 'a',
          'title': 'A',
          'chars': <Object?>[],
          'beats': <Object?>[],
        });

        text.should.be('slug: a\ntitle: A\nchars: []\nbeats: []\n');
      },
    );
  });

  group('writeYamlDocument — scalars', () {
    test(
      'Given a colour, when written, then the hash is quoted so it is not a comment',
      () {
        write({'colour': '#1b57c4'}).should.contain("colour: '#1b57c4'");
      },
    );

    test(
      'Given a whole float, when written, then it loses the pointless fraction',
      () {
        write({'lane': 120.0}).should.be('lane: 120\n');
        write({'lane': 120.5}).should.be('lane: 120.5\n');
      },
    );

    test(
      'Given a string with a colon and an apostrophe, when written, then it is single-quoted with the apostrophe doubled',
      () {
        write({
          'note': "The house: 27 don't ding it",
        }).should.be("note: 'The house: 27 don''t ding it'\n");
      },
    );

    test(
      'Given a string that is a number, when written, then it is quoted to keep its type',
      () {
        write({'title': '1999'}).should.be("title: '1999'\n");
      },
    );

    test(
      'Given unicode and an en dash, when written, then they are left as they are',
      () {
        write({'loc': '≈ 0–8 min'}).should.be('loc: ≈ 0–8 min\n');
      },
    );

    test(
      'Given a long line, when written, then it folds at the first single space past column 110',
      () {
        final text = write({'sub': 'abcdefghij ${'x' * 100} tail words here'});

        final lines = text.split('\n');
        lines[0].should.be('sub: abcdefghij ${'x' * 100}');
        lines[1].should.be('  tail words here');
        // The fold is a line break in YAML, so it reads back as one space.
        text
            .replaceAll('\n  ', ' ')
            .should
            .be('sub: abcdefghij ${'x' * 100} tail words here\n');
      },
    );

    test(
      'Given a long line with no space past the fold column, when written, then it stays long',
      () {
        final text = write({'sub': '${'x' * 60}.${'y' * 90}'});

        text.split('\n').first.length.should.be(156);
      },
    );
  });

  group('leadingCommentBlock', () {
    test(
      'Given a file with a header, when read, then the header comes back verbatim',
      () {
        const text = '# A film braid chart.\n#   cap      two lines\nslug: a\n';

        leadingCommentBlock(
          text,
        ).should.be(['# A film braid chart.', '#   cap      two lines']);
      },
    );

    test(
      'Given a document whose value contains a hash, when read, then only the leading block is taken',
      () {
        const text = 'colour: "#1b57c4"\n# not a header\n';

        leadingCommentBlock(text).should.beEmpty();
      },
    );

    test(
      'Given a header, when written then read back, then the header is unchanged',
      () {
        const header = ['# first', '#   indented note'];
        final text = writeYamlDocument({'slug': 'a'}, header: header);

        leadingCommentBlock(text).should.be(header);
      },
    );
  });
}
