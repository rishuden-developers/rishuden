/// UI の動作を切り替えるためのグローバルフラグ群。
///
/// - [useSimpleUI]: true の場合、ParkPage で新しい ToDo 風シンプルUIを使用する。
///   false の場合、従来のRPG風UIを使用する。
library ui_flags;

/// 新しい ToDo UI を使うかどうか
const bool useSimpleUI = true;

/// ToDo（未完了/完了）で「自分が作成したタスクのみ」を表示するか
/// false の場合、履修関連の全タスク（他人作成も含む）を表示します。
const bool showOnlyMyTasks = false;
