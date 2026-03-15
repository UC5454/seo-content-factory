# SEO Content Factory for Claude Code

**対策キーワードを投げるだけで、SEO×AIO最適化された記事が完成する全自動パイプライン。**

Claude Code の Agent Teams（AI社員間リレー）を活用し、7フェーズ×5エージェントが全自動で連携。SEO分析 → リサーチ → 執筆 → 3並列レビュー → 成果物格納まで、人間の介入なしで完走します。

## Architecture

```
Phase 0: SEO Analyst（SEO/AIO分析 → 指示書 + 構成案）
    ↓
Phase 1: Researcher（SEO特化リサーチ）
    ↓
Phase 2: Writer（SEO最適化記事執筆）
    ↓ 並行
Phase 3a: Designer（サムネイル）
Phase 3b: QA（記事品質レビュー）
Phase 3c: SEO Analyst（SEO/AIOスコアリング）
    ↓
Phase 4: Publisher（成果物格納・共有）
```

### vs 従来のSEOワークフロー

| | 従来（手動） | SEO Content Factory |
|---|---|---|
| フェーズ数 | 2（指示書→構成案で終わり） | 7（記事完成+格納まで全自動） |
| 競合分析 | 上位数記事を表面的に | 上位10記事を構造レベルで解析 |
| E-E-A-T | 考慮なし | 4軸×体験配置設計 |
| AI検索対応 | なし | Citabilityブロック・Direct Answer・Schema |
| 品質管理 | なし | SEO/AIO/E-E-A-T 3軸×100点スコアリング |
| 差し戻し | なし | スコア69以下で自動差し戻し→改善ループ |

## Quick Start

### 1. 前提条件

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) がインストール済み
- **どのターミナルでもOK**（iTerm2, Antigravity, Terminal.app, Warp, Linux terminals）
- Bash 4+

### 2. セットアップ

```bash
git clone https://github.com/UC5454/seo-content-factory.git
cd seo-content-factory

# 設定ファイルをコピー
cp .env.example .env
cp config.example.yaml config.yaml

# .env にAPIキー等を設定
vim .env

# config.yaml にチーム構成・パスを設定
vim config.yaml
```

### 3. 起動

```bash
# ヘッドレスモード（デフォルト。どのターミナルでも動く）
./tools/start-seo-factory.sh "対策キーワード"

# ユーザーメモ付き
./tools/start-seo-factory.sh "対策キーワード" "CTAはhttps://example.com/contactへ誘導"

# ビジュアルモード（各Phaseが新しいターミナルウィンドウで開く。macOS）
./tools/start-seo-factory.sh --visual "対策キーワード"
```

#### 実行モードの違い

| モード | 起動方法 | 特徴 |
|---|---|---|
| **ヘッドレス（デフォルト）** | `./start-seo-factory.sh "KW"` | どのOS・ターミナルでも動作。バックグラウンドで全Phase実行 |
| **ビジュアル** | `./start-seo-factory.sh --visual "KW"` | macOS専用。各Phaseが新しいターミナルウィンドウで開く |

ヘッドレスモードはAntigravity、Warp、Alacritty、Linux上のターミナルなど、claude CLIが動く環境なら全て対応。

### 4. Claude Code スラッシュコマンドとして使う

`.claude/commands/start-seo-factory.md` を自分の Claude Code プロジェクトにコピー:

```bash
cp .claude/commands/start-seo-factory.md /path/to/your/project/.claude/commands/
```

→ `/start-seo-factory Gemini Code Assist` で起動可能に。

## Configuration

### `.env`（APIキー・認証情報）

```bash
# .env.example を参照
ANTHROPIC_API_KEY=your-key-here
GOOGLE_WORKSPACE_EMAIL=your-email@example.com
```

### `config.yaml`（チーム構成・パス設定）

```yaml
# config.example.yaml を参照
base_dir: /path/to/your/project
seo_analyst_dir: /path/to/seo-analyst
researcher_dir: /path/to/researcher
writer_dir: /path/to/writer
# ...
```

## File Structure

```
seo-content-factory/
├── .claude/
│   └── commands/
│       └── start-seo-factory.md    # スラッシュコマンド定義
├── skills/
│   ├── seo-content-brief.md        # Phase 0: SEO/AIO分析スキル
│   └── seo-aio-review.md           # Phase 3c: SEO/AIOレビュースキル
├── tools/
│   ├── start-seo-factory.sh        # オーケストレーター（メイン）
│   ├── resolve-claude.sh           # Claude CLIパス解決
│   └── notify-complete.sh          # 完了通知
├── example-team/
│   ├── seo-analyst/                # Phase 0 & 3c の例
│   ├── researcher/                 # Phase 1 の例
│   ├── writer/                     # Phase 2 の例
│   ├── designer/                   # Phase 3a の例
│   ├── qa/                         # Phase 3b の例
│   └── publisher/                  # Phase 4 の例
├── config.example.yaml             # チーム構成テンプレート
├── .env.example                    # 環境変数テンプレート
├── .gitignore
├── LICENSE
└── README.md
```

## Phase Details

### Phase 0: SEO/AIO Analysis（SEO Analyst）

対策キーワードに対して:

1. **検索意図の自動分類**（Informational / Commercial / Transactional / Navigational）
2. **競合上位10記事の構造分析**（URL・文字数・h2数・Schema有無）
3. **PAA・LSI・共起語・サジェスト収集**
4. **E-E-A-T戦略設計**（体験配置・権威ソース特定・信頼性要素）
5. **AIO/GEO戦略**（Citabilityブロック・Direct Answer・マルチモーダル）
6. **指示書 + 構成案 + Schema設計**を一括出力
7. **品質ゲート検証**（構成案の網羅性・差別化・整合性チェック）

### Phase 1: SEO-Focused Research（Researcher）

通常のリサーチに加えて:
- SEOブリーフのE-E-A-T戦略に基づく裏付けデータ収集
- Direct Answer対象FAQの正確な回答データ
- コンテンツギャップの差別化トピック深掘り
- 全データに出典URL + 発行年月を必須付与

### Phase 2: SEO-Optimized Writing（Writer）

SEOブリーフの構成案に忠実に:
- 【CTA】タグ位置に自然なCTAを挿入
- 【AIO】タグ位置にCitabilityブロック（134-167語）を配置
- 【E-E-A-T:Experience】タグ位置に体験談を挿入
- KW密度1-3%、関連KW織り込み
- Direct Answer構造（冒頭結論→詳細展開）

### Phase 3: Triple Review（3 parallel）

| Agent | Focus | Output |
|---|---|---|
| Designer | サムネイル・アイキャッチ作成 | thumbnail + concept |
| QA | 記事品質・ファクトチェック | review.md |
| SEO Analyst | **SEO/AIOスコアリング** | seo-review.md |

#### SEO/AIO Scoring System（3軸×100点）

| Axis | Weight | Categories |
|---|---|---|
| SEO Score | 25% | Title(15) + Headings(20) + Content(30) + Technical(10) + Brief Compliance(25) |
| AIO/GEO Score | 25% | Citability(25) + Structure(20) + MultiModal(15) + Authority(20) + Technical(20) |
| E-E-A-T Score | 25% | Experience(30) + Expertise(25) + Authority(20) + Trust(25) |
| Brief Compliance | 25% | Topics(10) + Differentiation(8) + User Memo(7) |

**85+**: 承認 → Phase 4へ
**70-84**: 条件付き承認（軽微な改善指示付き）
**69以下**: 差し戻し → Writer に改善指示 → 再レビュー

### Phase 4: Publish（Publisher）

成果物をGoogle Drive等に格納し、最終報告。

## Customization

### エージェントの追加・変更

`config.yaml` でエージェント名・パス・iTerm2プロファイル名を変更するだけ。スキルファイル（`skills/*.md`）の指示内容も自由にカスタマイズ可能。

### スコアリング基準のカスタマイズ

`skills/seo-aio-review.md` 内のスコアリングテーブルを編集。業界・サイト特性に応じて配点を調整。

### CTA・運営者情報のカスタマイズ

`skills/seo-content-brief.md` 内のデフォルトCTA・運営者情報を自社に変更。

## Requirements

- **Claude Code CLI** v1.0+
- **Any OS**: macOS, Linux, WSL (headless mode works everywhere)
- **Any terminal**: iTerm2, Antigravity, Terminal.app, Warp, Alacritty, etc.
- **Bash** 4+
- Optional: Google Workspace integration (for Phase 4 Drive storage)
- Optional: `--visual` flag requires macOS (auto-detects terminal app)

## License

MIT License

## Credits

Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by [UC5454](https://github.com/UC5454).

SEO methodology based on [claude-seo](https://github.com/AgriciDaniel/claude-seo) skills architecture.
