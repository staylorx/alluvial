import 'dart:io';

import 'package:alluvial_store_yaml/alluvial_store_yaml.dart';
import 'package:alluvial_testing/alluvial_testing.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  late Directory store;

  setUp(() async {
    store = await Directory.systemTemp.createTemp('alluvial_folder_');
  });

  tearDown(() async {
    if (store.existsSync()) await store.delete(recursive: true);
  });

  storyRepositoryContract(
    adapterName: 'folder of YAML files',
    open: () => FolderStoryRepository(
      datasource: YamlFolderDatasource(directory: store.path),
    ),
    seed: (slug, document) => YamlFolderDatasource(
      directory: store.path,
    ).write(slug, document).run().then((_) {}),
  );

  group('FolderStoryRepository specifics', () {
    test(
      'Given a story written to disk, when the raw file is read, then it is YAML with a canonical layout',
      () async {
        final repository = FolderStoryRepository(
          datasource: YamlFolderDatasource(directory: store.path),
        );
        await repository.save(sampleStory(), key: 'a-sample');

        final text = File('${store.path}/a-sample.yaml').readAsStringSync();

        text.should.contain('slug: a-sample');
        text.should.contain('order:\n- lea\n- sam');
        text.should.contain("colour: '#1b57c4'");
        text.should.contain('beats:\n- name: ONE');
      },
    );

    test(
      'Given an existing file with a header block, when rewritten, then the header survives',
      () async {
        final file = File('${store.path}/a-sample.yaml')
          ..writeAsStringSync('# A header the author wrote\n# second line\n');
        final repository = FolderStoryRepository(
          datasource: YamlFolderDatasource(directory: store.path),
        );

        await repository.save(sampleStory(), key: 'a-sample');

        final text = file.readAsStringSync();
        text.should.contain('# A header the author wrote');
        text.should.contain('slug: a-sample');
      },
    );

    test(
      'Given a YAML syntax error, when loaded, then the store reports it rather than throwing',
      () async {
        File(
          '${store.path}/broken.yaml',
        ).writeAsStringSync('slug: [unclosed\n');
        final repository = FolderStoryRepository(
          datasource: YamlFolderDatasource(directory: store.path),
        );

        final loaded = await repository.load('broken');

        loaded.isLeft().should.be(true);
        loaded.getLeft().toNullable()!.code.should.be('store-unavailable');
      },
    );

    test(
      'Given a JSON file and no YAML beside it, when loaded, then the JSON is read',
      () async {
        File('${store.path}/legacy.json').writeAsStringSync('''
{"slug":"legacy","title":"Legacy","chars":[],"beats":[]}
''');
        final repository = FolderStoryRepository(
          datasource: YamlFolderDatasource(directory: store.path),
        );

        final loaded = await repository.load('legacy');

        loaded.isRight().should.be(true);
        loaded.getRight().toNullable()!.title.should.be('Legacy');
      },
    );

    test(
      'Given a story filed under a key that is not its slug, when saved, then it lands under the key',
      () async {
        // A two-clock chart shares the film's slug while living in its own
        // file, so writing by slug would overwrite the film.
        final repository = FolderStoryRepository(
          datasource: YamlFolderDatasource(directory: store.path),
        );

        await repository.save(sampleStory(), key: 'a-sample-timechart');

        File(
          '${store.path}/a-sample-timechart.yaml',
        ).existsSync().should.be(true);
        File('${store.path}/a-sample.yaml').existsSync().should.be(false);
        File(
          '${store.path}/a-sample-timechart.yaml',
        ).readAsStringSync().should.contain('slug: a-sample');
      },
    );

    test(
      'Given a store directory that does not exist, when listed, then it is empty rather than an error',
      () async {
        final repository = FolderStoryRepository(
          datasource: YamlFolderDatasource(directory: '${store.path}/nope'),
        );

        final listed = await repository.list();

        listed.isRight().should.be(true);
        listed.getRight().toNullable()!.should.beEmpty();
      },
    );
  });
}
