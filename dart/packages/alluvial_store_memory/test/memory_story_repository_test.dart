import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_store_memory/alluvial_store_memory.dart';
import 'package:alluvial_testing/alluvial_testing.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Map<String, Object?>> documents;

  setUp(() {
    documents = <String, Map<String, Object?>>{};
  });

  storyRepositoryContract(
    adapterName: 'in-memory store',
    open: () =>
        MemoryStoryRepository(datasource: MemoryStoryDatasource(documents)),
    seed: (slug, document) => MemoryStoryDatasource(
      documents,
    ).write(slug, document).run().then((_) {}),
  );

  group('MemoryStoryRepository specifics', () {
    test(
      'Given a document written straight into the store, when read, then the caller cannot mutate the store',
      () async {
        final datasource = MemoryStoryDatasource(documents);
        await datasource.write('a-sample', {
          'slug': 'a-sample',
          'title': 'A Sample',
        }).run();

        final read = await datasource.read('a-sample').run();
        read.getRight().toNullable()!['title'] = 'Tampered';

        final again = await datasource.read('a-sample').run();
        again.getRight().toNullable()!['title'].should.be('A Sample');
      },
    );

    test(
      'Given nothing stored, when a missing slug is read, then it reports the document missing',
      () async {
        final read = await MemoryStoryDatasource(
          documents,
        ).read('nobody').run();

        read.isLeft().should.be(true);
        read.getLeft().toNullable()!.should.beAssignableTo<DocumentMissing>();
      },
    );
  });
}
