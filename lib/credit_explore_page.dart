import 'package:flutter/material.dart';
import 'credit_result_page.dart'; // 既存のCreditResultPageをインポート

// CreditExplorePage 自体は、検索結果を受け取るページではありません。
// 検索ロジックや検索結果は CreditReviewPage の中で処理するか、
// あるいは検索結果表示用の専用のページ (例: SearchResultsPage) を別途定義します。
class CreditExplorePage extends StatelessWidget {
  const CreditExplorePage({super.key}); // ★正しいconstコンストラクタ★

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('探索ページ'), // ★タイトルを修正★
        backgroundColor: Colors.blueGrey, // 例として色を追加
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '単位レビュー探索ページです！', // テキストも修正
              style: TextStyle(fontSize: 20, color: Colors.black87),
            ),
            const SizedBox(height: 30), // スペース

            ElevatedButton(
              child: const Text('CreditResultPageへ'), // CreditResultPageへ遷移
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreditResultPage(),
                  ),
                );
              },
            ),
            // 必要であれば、他のボタンやコンテンツをここに追加
          ],
        ),
      ),
    );
  }
}

// 注意: 以前定義した SearchResultsPage は、
// 別の目的（検索結果表示）のために CreditReviewPage の中に定義されていました。
// もし SearchResultsPage を CreditExplorePage と同じファイルに置く場合は、
// そのクラスの定義もここに追加し、必要に応じて引数を持つように修正してください。
// 例:
/*
class SearchResultsPage extends StatelessWidget {
  final String query;
  final String? filter;

  const SearchResultsPage({super.key, required this.query, this.filter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('検索結果'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('検索クエリ: "$query"'),
            if (filter != null) Text('絞り込み条件: "$filter"'),
            const SizedBox(height: 20),
            const Text('ここに検索結果が表示されます。'),
          ],
        ),
      ),
    );
  }
}
*/
