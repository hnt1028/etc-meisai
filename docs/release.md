# リリースの自動化

`release/*` ブランチを push すると、GitHub Actions（`.github/workflows/release.yml`）が、署名した APK をビルドし、タグとドラフトの GitHub Release を作って、APK を添付する。ブランチと `master` への流れは [git.md](git.md) に従う。

## 動き

1. `release/x.y.z` を `develop` から切り、`pubspec.yaml` の `version` を変更して push する
2. ワークフローが、`version`（`x.y.z+n` の `x.y.z`）から、タグ名 `vx.y.z` を決める
3. 同じタグが既にあるときは、失敗する（`version` を変える）
4. リリース用の鍵で署名した APK（`etc-meisai-vx.y.z.apk`）をビルドする
5. タグを作って push し、**ドラフト**の Release に APK を添付する
6. 利用者が、Release を確認し、公開する

- 公開するまで、ドラフトのため、他の人には見えない
- タグは、`release/*` ブランチの先頭に付く（`master` へのマージコミットではない）
- 鍵の Secrets が無いときは、署名できないため、失敗する（デバッグ鍵の APK は、Release に載せない）

## 署名の鍵

- 鍵（keystore）とパスワードは、**リポジトリに入れない**。チャットにも貼らない
- 一度作った鍵は、ずっと使う。変えると、入れ替え（上書き更新）ができなくなる。紛失しないよう、パスワード管理ツールなどで保管する
- ローカルのビルド（`flutter build apk --release`）は、鍵が無いと、デバッグ鍵で署名する。`android/key.properties` を置くと、リリース鍵で署名する（`.gitignore` 済み）

### 鍵を作る（Windows PowerShell）

`keytool` は Android Studio の JDK（`jbr`）に入っている。

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$HOME\etc-meisai-release.jks" -alias etc-meisai -keyalg RSA -keysize 2048 -validity 10000
```

パスワードと名前などは、対話で入力する（入力は画面に出ない）。

### Secrets に登録する

リポジトリの Settings → Secrets and variables → Actions に、次の4つを登録する。`gh secret set` は、値を対話で聞くため、履歴に残らない。

| 名前 | 中身 |
|---|---|
| `RELEASE_KEYSTORE_BASE64` | keystore ファイルを Base64 にしたもの |
| `RELEASE_KEYSTORE_PASSWORD` | keystore のパスワード |
| `RELEASE_KEY_ALIAS` | 別名（上の例では `etc-meisai`） |
| `RELEASE_KEY_PASSWORD` | 鍵のパスワード（`keytool` で聞かれなかったときは、keystore と同じ） |

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\etc-meisai-release.jks")) | gh secret set RELEASE_KEYSTORE_BASE64 --repo hnt1028/etc-meisai
gh secret set RELEASE_KEYSTORE_PASSWORD --repo hnt1028/etc-meisai
gh secret set RELEASE_KEY_ALIAS --repo hnt1028/etc-meisai
gh secret set RELEASE_KEY_PASSWORD --repo hnt1028/etc-meisai
```

### ローカルで署名する（任意）

`android/key.properties` を作る（コミットしない）。

```properties
storeFile=C:\Users\<利用者>\etc-meisai-release.jks
storePassword=<パスワード>
keyAlias=etc-meisai
keyPassword=<パスワード>
```

## 注意

- 鍵を替えるときは、入れ替えができない旨を、利用者に伝える
- ワークフローには、`contents: write`（タグと Release の作成）だけを許す
