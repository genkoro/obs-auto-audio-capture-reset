-- SPDX-License-Identifier: MIT
--[[
MIT License

Copyright (c) 2026 Anonymous

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- Windows版OBS専用のキャプチャ音声自動リセット。
-- 趣味で制作。自由に利用できますが無保証です（上記ライセンス参照）。
-- 言語設定が日本語以外だと英語で表示されます。
-- リセットボタンは、音源一覧の再読み込みと画面更新の再接続も兼ねます。

-- 設定項目と画面に表示する文。

local obs = obslua

-- 読み込み時に言語を選ぶ。OBSの再起動後に反映される。
-- 言語を取得できない場合も英語にする。
local function obs_uses_japanese()
    if type(obs.obs_get_locale) ~= "function" then return false end
    local ok, locale = pcall(obs.obs_get_locale)
    if not ok or type(locale) ~= "string" then return false end
    locale = locale:lower():gsub("_", "-")
    return locale == "ja" or locale:match("^ja%-") ~= nil
end

local USE_JAPANESE = obs_uses_japanese()
local TEXT = {
    ja = {
        manual_caption = "今すぐリセット",
        countdown_prefix = "リセット",
        label_settings = "設定",
        label_status = "状態",
        label_auto = "自動",
        label_notice = "説明欄",
        label_source = "音源",
        label_interval = "間隔 (分)",
        label_mode = "動作",
        placeholder = "-- 音源を選んでください --",
        mode_outputs = "録画・配信中のみ",
        mode_always = "常時、自動リセット",
        mode_off = "自動リセットしない",
        help_source = "リセットする音源を選びます。\nゲームキャプチャ、ウィンドウキャプチャ、アプリケーション音声キャプチャが対象です。\n音源を追加・削除・改名すると、この一覧は自動で更新されます。",
        help_interval = "自動リセットの間隔です。1～1500分（25時間）で設定できます。\n自動リセットが始まってから、この時間が経ったあとに最初のリセットを行います。",
        help_mode = "録画・配信中のみ：録画か配信のどちらかが始まると自動リセットを始め、両方が止まると止めます。\n常時、自動リセット：録画・配信に関係なく動き続けます。\n自動リセットしない：自動リセットを止めます。音声の取り込みは続き、手動リセットは使えます。\nこの設定は保存されます。",
        help_manual = "音声キャプチャを今すぐ1回リセットします。\n自動リセットの設定に関係なく使えます。準備不足のときは何も実行されません。\n自動リセット中は、成功すると間隔も数え直します。",
        compat_obs = "このスクリプトを使うには、OBS 29.1以降が必要です。OBSを更新してください。",
        compat_windows = "このスクリプトはWindows版のOBS専用です。",
        compat_app_audio = "このWindowsでは、OBSの「アプリケーション音声キャプチャ」が使えません。\n",
        compat_windows_version = "このスクリプトを使うには、Windows 10 バージョン2004（ビルド19041）以降が必要です。",
        detail_prefix = "\n詳細：",
        audio_steps_prefix = "OBS本体で「",
        audio_steps_suffix = "」のプロパティを開き、「音声をキャプチャ」をONにしてください。",
        error_settings = "設定を取得できませんでした。",
        status_select = "▲ 音源を選んでください",
        status_select_help = "上の「音源」で選択。",
        status_missing = "▲ 音源が見つかりません",
        status_missing_help = "「音源」で選び直し。",
        status_unsupported = "▲ この音源は使えません",
        status_supported_first = "ゲーム／ウィンドウ／",
        status_supported_second = "アプリ音声が対象です。",
        status_audio_off = "▲ 音声キャプチャがOFF",
        status_properties = "音源のプロパティで",
        status_enable_audio = "「音声をキャプチャ」をON",
        status_no_window = "▲ 取り込み先が未設定",
        status_select_window = "ウィンドウを選択。",
        status_waiting = "○ 録画・配信の開始待ち",
        status_waiting_help = "開始後に自動で実行。",
        status_off = "○ 自動リセットは停止中",
        status_off_help = "手動リセットは使えます",
        status_running = "● 自動リセット中",
        status_running_help = "設定した間隔で実行。",
        kind_manual = "手動",
        last_prefix = "前回 ",
        kind_open = "（",
        kind_close = "）",
        status_requested = "リセットを要求しました",
        status_failed = "失敗：スクリプトログ参照",
        ui_stopped = "表示の自動更新を停止しました。\n自動リセットの設定は変わりません。",
        source_missing_suffix = "（見つかりません）",
        error_audio_windows = "内部音声の操作にはWindows版OBSが必要です。",
        error_audio_connection = "OBSの音声機能に接続できませんでした。",
        error_audio_api = "内部音声の操作に必要なAPIが見つかりません：",
        error_multiple_audio = "内部音声が複数あり、操作する音源を特定できませんでした。",
        error_audio_target = "音声の取り込み先を取得できませんでした。",
        error_audio_data = "音声キャプチャの変更用データを作成できませんでした。",
        error_uuid_api = "選択した音源を識別するAPIが見つかりません。",
        error_source_read = "選択した音源を取得できませんでした。",
        error_uuid_mismatch = "選択した音源の識別情報が一致しません。",
        error_internal_missing = "内部音声が見つかりません。\nOBS本体で音声キャプチャと取り込み先の設定を確認してください。",
        error_internal_target = "内部音声の取り込み先を取得できませんでした。",
        error_internal_data = "内部音声の変更用データを作成できませんでした。",
        error_target_format = "音声の取り込み先が未設定か、設定を読み取れません。\nOBS本体で取り込むウィンドウを選び直してください。",
        error_not_restored = "取り込み先の設定が元に戻っていません。",
        restore_done = " / 取り込み先の設定は元に戻しました。",
        restore_failed = " / 取り込み先の設定を元に戻せませんでした：",
        restore_help = " / OBS本体で音声キャプチャの設定を確認してください。",
        reset_obs_busy = "OBSの処理中のため、リセットを実行しませんでした。\n処理が終わってから、もう一度実行してください。",
        reset_in_progress = "リセットの処理中です。\n処理が終わってから、もう一度実行してください。",
        reset_no_source = "音源が選択されていません。\n「音源」から、自動リセットする音源を選んでください。",
        reset_missing_prefix = "選択した音源「",
        reset_missing_suffix = "」が見つかりません。\n音源の選択欄から選び直してください。",
        reset_unsupported = "この音源は音声リセットに対応していません。\nゲーム／ウィンドウ／アプリケーションキャプチャから選んでください。\n選択した音源：",
        reset_audio_off = "音声キャプチャが無効のため、リセットを実行しませんでした。\n",
        reset_failed = "音声キャプチャのリセットに失敗しました。\n選択した音源：",
        reset_requested = "音声キャプチャのリセットを要求し、取り込み先の設定を元に戻しました。\n選択した音源：",
        remaining_hours = "%d時間%02d分%02d秒",
        remaining_minutes = "%d分%02d秒",
        static_preparing = "自動：準備中",
        static_select = "自動：音源を選んでください",
        static_waiting = "自動：録画・配信待ち",
        static_off = "自動：停止中",
        static_check = "自動：設定を確認してください",
        static_running = "自動：動作中",
        live_preparing = "準備中",
        live_select = "：音源を選択",
        live_waiting = "：録画・配信待ち",
        live_off = "：停止中",
        live_check = "：設定を確認",
        live_remaining = "まで ",
        error_ui_windows = "残り時間の表示には、Windows版OBS（64ビット）が必要です。",
        error_ui_connection = "OBSの画面表示機能に接続できませんでした。",
        error_ui_api = "画面更新に必要なAPIが見つかりません：",
        error_ui_encoding = "表示用の文字を変換できませんでした。",
        static_prefix = "自動：",
        error_ui_create = "画面更新用の接続を作成できませんでした。",
        error_ui_connect = "画面更新の接続を確認できませんでした：",
        error_ui_post = "表示の更新要求をOBSに渡せませんでした。",
        error_source_reload = "音源一覧の自動更新を要求できませんでした。",
        source_removed = "音源が削除されました。",
        title_prefix = "<b>キャプチャ音声の自動リセット v",
        version_log = "v%s / 表示言語：日本語",
    },
    en = {
        manual_caption = "Reset now",
        countdown_prefix = "Reset",
        label_settings = "Settings",
        label_status = "Status",
        label_auto = "Auto",
        label_notice = "Details",
        label_source = "Source",
        label_interval = "Interval (min)",
        label_mode = "Mode",
        placeholder = "-- Select a source --",
        mode_outputs = "While recording/streaming",
        mode_always = "Always",
        mode_off = "Off (manual only)",
        help_source = "Select the source whose audio capture will be reset.\nSupports Game Capture, Window Capture, and Application Audio Capture.\nThe list updates automatically when sources are added, removed, or renamed.",
        help_interval = "Time between automatic resets: 1 to 1500 minutes (25 hours).\nThe first reset happens after one full interval of automatic operation.",
        help_mode = "While recording/streaming: automatic resets start when either recording or streaming starts, and stop when both stop.\nAlways: automatic resets run even when neither is active.\nOff (manual only): automatic resets stop; audio capture continues.\nThis setting is saved.",
        help_manual = "Reset audio capture once now, regardless of the automatic mode.\nNothing is reset if the source is not ready.\nIf automatic resets are running, a successful request also restarts the interval.",
        compat_obs = "This script requires OBS 29.1 or later. Please update OBS.",
        compat_windows = "This script requires OBS for Windows.",
        compat_app_audio = "Application Audio Capture is unavailable on this version of Windows.\n",
        compat_windows_version = "This script requires Windows 10 version 2004 (build 19041) or later.",
        detail_prefix = "\nDetails: ",
        audio_steps_prefix = "In OBS, open the properties of \"",
        audio_steps_suffix = "\" and enable \"Capture Audio\".",
        error_settings = "Could not read the source settings.",
        status_select = "▲ Select a source",
        status_select_help = "Choose it under Source.",
        status_missing = "▲ Source not found",
        status_missing_help = "Select another source.",
        status_unsupported = "▲ Unsupported source",
        status_supported_first = "Use game, window, or",
        status_supported_second = "application audio capture.",
        status_audio_off = "▲ Audio capture is OFF",
        status_properties = "In source properties,",
        status_enable_audio = "enable \"Capture Audio\".",
        status_no_window = "▲ No capture window",
        status_select_window = "select a window.",
        status_waiting = "○ Waiting for recording",
        status_waiting_help = "or streaming to start.",
        status_off = "○ Auto reset is off",
        status_off_help = "Manual reset is available.",
        status_running = "● Auto reset is on",
        status_running_help = "Runs at the set interval.",
        kind_manual = "Manual",
        last_prefix = "Last ",
        kind_open = " (",
        kind_close = ")",
        status_requested = "Reset requested.",
        status_failed = "Failed: see Script Log",
        ui_stopped = "Live display updates have stopped.\nAutomatic reset settings are unchanged.",
        source_missing_suffix = " (not found)",
        error_audio_windows = "Accessing internal audio requires OBS for Windows.",
        error_audio_connection = "Could not connect to the OBS audio API.",
        error_audio_api = "Required internal audio API was not found: ",
        error_multiple_audio = "Found multiple internal audio sources; could not determine which one to reset.",
        error_audio_target = "Could not read the audio capture target.",
        error_audio_data = "Could not create data to update audio capture.",
        error_uuid_api = "The API needed to identify the selected source was not found.",
        error_source_read = "Could not access the selected source.",
        error_uuid_mismatch = "The selected source identity does not match.",
        error_internal_missing = "The internal audio source was not found.\nCheck audio capture and the target window in the OBS source properties.",
        error_internal_target = "Could not read the internal audio capture target.",
        error_internal_data = "Could not create data to update internal audio capture.",
        error_target_format = "The audio capture target is not set or could not be read.\nReselect the target window in the OBS source properties.",
        error_not_restored = "The capture target settings were not restored.",
        restore_done = " / The capture target settings were restored.",
        restore_failed = " / Could not restore the capture target settings: ",
        restore_help = " / Check the audio capture settings in OBS.",
        reset_obs_busy = "Reset skipped because OBS is busy.\nWait for the current operation to finish, then try again.",
        reset_in_progress = "A reset is already in progress.\nWait for it to finish, then try again.",
        reset_no_source = "No source is selected.\nSelect the source to reset under Source.",
        reset_missing_prefix = "The selected source \"",
        reset_missing_suffix = "\" was not found.\nSelect another source under Source.",
        reset_unsupported = "This source does not support audio resets.\nChoose Game Capture, Window Capture, or Application Audio Capture.\nSelected source: ",
        reset_audio_off = "Reset skipped because audio capture is disabled.\n",
        reset_failed = "Audio capture reset failed.\nSelected source: ",
        reset_requested = "Audio capture reset requested and capture target settings restored.\nSelected source: ",
        remaining_hours = "%dh %02dm %02ds",
        remaining_minutes = "%dm %02ds",
        static_preparing = "Auto: preparing",
        static_select = "Auto: select a source",
        static_waiting = "Auto: waiting to start",
        static_off = "Auto: off",
        static_check = "Auto: check settings",
        static_running = "Auto: running",
        live_preparing = ": preparing",
        live_select = ": select a source",
        live_waiting = ": waiting to start",
        live_off = ": off",
        live_check = ": check settings",
        live_remaining = " in ",
        error_ui_windows = "The countdown display requires 64-bit OBS for Windows.",
        error_ui_connection = "Could not connect to the OBS display API.",
        error_ui_api = "Required display API was not found: ",
        error_ui_encoding = "Could not convert text for display.",
        static_prefix = "Auto: ",
        error_ui_create = "Could not create a connection for display updates.",
        error_ui_connect = "Could not verify the display update connection: ",
        error_ui_post = "Could not send the display update request to OBS.",
        error_source_reload = "Could not request an automatic source list update.",
        source_removed = "Source was removed.",
        title_prefix = "<b>Auto Audio Capture Reset v",
        version_log = "v%s / Display language: English",
    },
}
local T = USE_JAPANESE and TEXT.ja or TEXT.en

-- OBSが設定を引き継げるよう、登録後のファイル名と保存場所は変えない。
local VERSION = "3.4.6"
local AUDIO_KEY = "capture_audio"
local APPLICATION_AUDIO_ID = "wasapi_process_output_capture"
local COUNTDOWN_UPDATE_MS = 1000
-- リセットボタンの文は固定し、画面更新処理ではこの文を目印に幅を設定する。
local MANUAL_CAPTION = T.manual_caption
-- 動的表示には接頭辞を付け、固定表示には付けないのでスタイルシートが作り直した固定表示を上書きしない。
local COUNTDOWN_PREFIX = T.countdown_prefix
local MIN_TIMER_MINUTES = 1
local MAX_TIMER_MINUTES = 1500 -- 上限は25時間。

local LABEL = {
    settings_group = T.label_settings,
    status_group = T.label_status,
    countdown = T.label_auto,
    notice = T.label_notice,
    source = T.label_source,
    -- 数値欄に単位を付けると数字入力の妨げになるためラベル側に置く。
    interval = T.label_interval,
    mode = T.label_mode,
    placeholder = T.placeholder,
}

-- 2つのチェックボックスを1つの動作選択にまとめる。
-- 選択値を内部の2つのフラグ follow_outputs と script_enabled に対応付ける。
-- outputs：follow_outputs = true（録画または配信中だけ動作）。
-- always：follow_outputs = false、script_enabled = true（常時動作）。
-- off：follow_outputs = false、script_enabled = false（自動動作を停止）。
local MODE_ORDER = {"outputs", "always", "off"}
local MODE_LABEL = {
    outputs = T.mode_outputs,
    always = T.mode_always,
    off = T.mode_off,
}

local HELP = {
    source_name = T.help_source,
    interval_minutes = T.help_interval,
    mode = T.help_mode,
    test_now = T.help_manual,
    -- OBSが文をHTMLに書き換えると画面更新がその行を見つけられないので。
    -- 残り時間の行にはヒントを付けない。
}

-- 実行中の状態。

local source_name = ""
local source_uuid = nil
local sources_dirty = false
local interval_minutes = 30
local script_enabled = false
local follow_outputs = true
local loaded = false
local collection_changing = false
local exiting = false
local saved_settings = nil
local next_refresh_at = nil
local last_countdown_text = nil
local ui_api = nil
local ui_api_attempted = false
local ui_bridges = {}
local ui_updates_failed = false
local ui_connected = false
local ui_reload_failed = false
local update_countdown
local countdown_tick
local countdown_caption
local sync_controls
local configure_script_view

local refresh_in_progress = false
local audio_bridge = nil

-- 現在の状態と説明欄に表示する直近の結果を保持する。
local last_result = nil -- 保持する項目：{time, kind = "auto"|"manual", ok, logged}。
local event_note = nil

-- メッセージと音源の設定案内。

local function timer_time()
    -- OBSのLuaタイマーと同じ、逆戻りしないフレーム時刻を使う（単位はナノ秒）。
    return obs.obs_get_video_frame_time()
end

local function output_active()
    return obs.obs_frontend_recording_active() or obs.obs_frontend_streaming_active()
end

local function is_target_type(source)
    local id = obs.obs_source_get_unversioned_id(source)
    return id == "game_capture" or id == "window_capture" or id == APPLICATION_AUDIO_ID
end

-- このスクリプトが動作できない環境を、一度だけ確認する。
-- 結果はログのエラーだけにせず、スクリプト画面の先頭に表示する。
-- error：動作に必須のAPIがない場合、またはWindows版OBSでない場合は停止する。
-- 音源識別に使う obs_source_get_uuid は、OBS 29.1以降で利用できる。
-- リセット対象の音源はいずれもWindows専用のため、他のOSでは動作させない。
-- warning：案内だけを出す。「アプリケーション音声キャプチャ」は、
-- Windows 10 バージョン2004（ビルド19041）以降で登録される。
-- ゲーム／ウィンドウキャプチャの音声も、この機能に依存する。
-- 環境の判定違いで動く構成を止めないよう、警告だけでは機能を無効にしない。
local compat_checked, compat_error, compat_warning = false, nil, nil
local function compatibility()
    if not compat_checked then
        compat_checked = true
        if type(obs.obs_source_get_uuid) ~= "function"
            or type(obs.obs_property_text_set_info_word_wrap) ~= "function" then
            compat_error = T.compat_obs
        else
            local has_ffi, ffi = pcall(require, "ffi")
            if has_ffi and type(ffi) == "table" and ffi.os ~= "Windows" then
                compat_error = T.compat_windows
            end
        end
        if compat_error == nil and type(obs.obs_source_get_display_name) == "function" then
            local ok, name = pcall(obs.obs_source_get_display_name, APPLICATION_AUDIO_ID)
            if ok and (name == nil or name == "") then
                compat_warning = T.compat_app_audio
                    .. T.compat_windows_version
            end
        end
    end
    return compat_error, compat_warning
end

local function current_mode()
    if follow_outputs then return "outputs" end
    return script_enabled and "always" or "off"
end

local function log_result(level, message)
    -- ログ画面を開かずに結果を記録する。1回の出来事を1行にまとめる。
    obs.script_log(level, (message:gsub("[\r\n]+", " / ")))
end

local function failure_message(message, detail)
    return message .. T.detail_prefix .. tostring(detail)
end

local function audio_checkbox_steps(name)
    return T.audio_steps_prefix .. name .. T.audio_steps_suffix
end

-- 直近のリセット結果を保持し、説明欄に表示する。
-- countdown_tick により1秒以内に表示が更新されるため、
-- 設定を触らなくても、自動リセットの結果が画面に反映される。
local function record_result(kind, ok, logged)
    last_result = {time = os.date("%H:%M:%S"), kind = kind, ok = ok == true, logged = logged == true}
    sources_dirty = true
end

-- 音源の選択と状態の確認。

local function has_audio_checkbox(source)
    local id = obs.obs_source_get_unversioned_id(source)
    if id ~= "game_capture" and id ~= "window_capture" then
        return false
    end
    local props = obs.obs_source_properties(source)
    if props == nil then
        return false
    end
    local available = obs.obs_properties_get(props, AUDIO_KEY) ~= nil
    obs.obs_properties_destroy(props)
    return available
end

-- 選んだ音源がリセット可能な状態か確認する。
-- 判定値：none / missing / unsupported / setup_audio / setup_window / ready。
-- full が有効なら、ゲーム／ウィンドウ音源に音声設定があることも確認する。
-- この確認ではプロパティ一覧を作るため、画面を作り直すときだけ行い、
-- 毎秒の表示更新からは呼ばない。
local function target_check(full)
    if source_name == "" then return "none" end
    local source = obs.obs_get_source_by_name(source_name)
    if source == nil then return "missing" end
    local result = "ready"
    local settings
    local ok = pcall(function()
        if obs.obs_source_removed(source) or not is_target_type(source) then
            result = "unsupported"
            return
        end
        local application = obs.obs_source_get_unversioned_id(source) == APPLICATION_AUDIO_ID
        if full and not application and not has_audio_checkbox(source) then
            result = "unsupported"
            return
        end
        settings = obs.obs_source_get_settings(source)
        if settings == nil then error(T.error_settings) end
        if application then
            if obs.obs_data_get_string(settings, "window") == "" then result = "setup_window" end
        elseif not obs.obs_data_get_bool(settings, AUDIO_KEY) then
            result = "setup_audio"
        end
    end)
    if settings ~= nil then obs.obs_data_release(settings) end
    obs.obs_source_release(source)
    if not ok then return "unsupported" end
    return result
end

local function target_ready()
    return target_check(false) == "ready"
end

-- 結果表示の前後で高さが変わらないよう、短い文を5行分用意する。
-- 音源名は選択欄とログだけに出し、長い名前で説明欄の幅が広がるのを防ぐ。
-- 説明欄には、OBS標準の縦方向に伸びる複数行入力欄で通常の文字列を表示する。
local function status_text(full)
    local check = target_check(full)
    local head, first, second
    if check == "none" then
        head = T.status_select
        first = T.status_select_help
    elseif check == "missing" then
        head = T.status_missing
        first = T.status_missing_help
    elseif check == "unsupported" then
        head = T.status_unsupported
        first = T.status_supported_first
        second = T.status_supported_second
    elseif check == "setup_audio" then
        head = T.status_audio_off
        first = T.status_properties
        second = T.status_enable_audio
    elseif check == "setup_window" then
        head = T.status_no_window
        first = T.status_properties
        second = T.status_select_window
    elseif not script_enabled then
        if follow_outputs then
            head = T.status_waiting
            first = T.status_waiting_help
        else
            head = T.status_off
            first = T.status_off_help
        end
    else
        head = T.status_running
        first = T.status_running_help
    end
    local lines = {head, first, second or "", "", ""}
    if event_note ~= nil then
        lines[4] = event_note
    elseif last_result ~= nil then
        local kind = last_result.kind == "manual" and T.kind_manual or T.label_auto
        lines[4] = T.last_prefix .. last_result.time .. T.kind_open .. kind .. T.kind_close
        lines[5] = last_result.ok and T.status_requested or T.status_failed
    end
    return table.concat(lines, "\n")
end

-- 説明欄と残り時間の行は、ラベルではなく設定データから表示内容を読む。
-- どちらかの内容が変わり得るときは、両方を設定データへ書き込み、
-- 画面を更新した際に古い内容が出ないようにする。
-- 画面の再構築でOBSが破棄するため、プロパティのポインターは保持しない。
local function update_notice(full)
    if saved_settings ~= nil then
        obs.obs_data_set_string(saved_settings, "notice", status_text(full))
        obs.obs_data_set_string(saved_settings, "countdown", countdown_caption())
    end
end

local function fail_ui(detail)
    local first_failure = not ui_updates_failed
    ui_updates_failed = true
    ui_connected = false
    last_countdown_text = nil
    sources_dirty = true
    if loaded and not exiting then update_notice(false) end
    if first_failure then
        log_result(obs.LOG_WARNING, failure_message(
            T.ui_stopped, detail))
    end
end

-- 選択中の音源を記憶し、名前変更や削除に追従する。
-- 下にある音源変更の通知処理で、この情報を使う。
local function track_source()
    source_uuid = nil
    if source_name == "" then return end
    local source = obs.obs_get_source_by_name(source_name)
    if source == nil then return end
    source_uuid = obs.obs_source_get_uuid(source)
    obs.obs_source_release(source)
end

local function settings_modified(props, settings)
    -- 他の項目を更新する前に音源の選択を反映する。OBSの処理中は変更を受け付けず、
    -- 選択欄を、実際に処理対象となっている音源に戻す。
    if not loaded or exiting or collection_changing or refresh_in_progress then
        obs.obs_data_set_string(settings, "mode", current_mode())
    end
    script_update(settings)
    sync_controls(props)
    return true
end

local function populate_sources(dropdown)
    obs.obs_property_list_clear(dropdown)
    obs.obs_property_list_add_string(dropdown, LABEL.placeholder, "")
    local names = {}
    local found_selected = false
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            if is_target_type(source) and not obs.obs_source_removed(source) then
                local name = obs.obs_source_get_name(source)
                table.insert(names, name)
                if name == source_name then
                    found_selected = true
                end
            end
        end
        obs.source_list_release(sources)
    end
    table.sort(names)
    for _, name in ipairs(names) do
        obs.obs_property_list_add_string(dropdown, name, name)
    end
    if source_name ~= "" and not found_selected then
        obs.obs_property_list_add_string(dropdown, source_name .. T.source_missing_suffix, source_name)
    end
end

-- リセット処理。言語で切り替えるのはメッセージだけ。

-- 実際に音声を取り込む内部音源だけを更新する。映像側の親音源を更新すると、
-- 変更が遅延・統合され、取り込み中の映像までリセットされる場合がある。
local function initialize_audio_bridge()
    if audio_bridge ~= nil then return audio_bridge end
    local ffi = require("ffi")
    if ffi.os ~= "Windows" then error(T.error_audio_windows) end
    if not pcall(ffi.typeof, "obs_aar_restart_source") then
        ffi.cdef[[
            typedef struct obs_aar_restart_source obs_aar_restart_source;
            typedef struct obs_aar_restart_data obs_aar_restart_data;
            typedef void (*obs_aar_restart_enum)(obs_aar_restart_source *, obs_aar_restart_source *, void *);
            void * __stdcall GetModuleHandleA(const char *);
            void * __stdcall GetProcAddress(void *, const char *);
        ]]
    end
    local kernel = ffi.load("kernel32")
    local module = kernel.GetModuleHandleA("obs.dll")
    if module == nil then error(T.error_audio_connection) end
    local function bind(name, signature)
        local address = kernel.GetProcAddress(module, name)
        if address == nil then error(T.error_audio_api .. name) end
        return ffi.cast(signature, address)
    end
    local api = {}
    api.by_name = bind("obs_get_source_by_name", "obs_aar_restart_source *(*)(const char *)")
    api.retain = bind("obs_source_get_ref", "obs_aar_restart_source *(*)(obs_aar_restart_source *)")
    api.release = bind("obs_source_release", "void (*)(obs_aar_restart_source *)")
    api.id = bind("obs_source_get_unversioned_id", "const char *(*)(const obs_aar_restart_source *)")
    api.uuid = bind("obs_source_get_uuid", "const char *(*)(const obs_aar_restart_source *)")
    api.enumerate = bind("obs_source_enum_active_sources",
        "void (*)(obs_aar_restart_source *, obs_aar_restart_enum, void *)")
    api.settings = bind("obs_source_get_settings", "obs_aar_restart_data *(*)(const obs_aar_restart_source *)")
    api.create = bind("obs_data_create", "obs_aar_restart_data *(*)(void)")
    api.release_data = bind("obs_data_release", "void (*)(obs_aar_restart_data *)")
    api.get_string = bind("obs_data_get_string", "const char *(*)(obs_aar_restart_data *, const char *)")
    api.set_string = bind("obs_data_set_string", "void (*)(obs_aar_restart_data *, const char *, const char *)")
    api.update = bind("obs_source_update", "void (*)(obs_aar_restart_source *, obs_aar_restart_data *)")
    function api.text(value) return value ~= nil and ffi.string(value) or "" end
    function api.find_audio(parent)
        local child, problem
        local callback = ffi.cast("obs_aar_restart_enum", function(_, candidate)
            local ok, err = pcall(function()
                if api.text(api.id(candidate)) == APPLICATION_AUDIO_ID then
                    if child ~= nil then error(T.error_multiple_audio) end
                    child = api.retain(candidate)
                end
            end)
            if not ok then problem = err end
        end)
        -- OBSの音源列挙は、この呼び出し中に同期的にコールバックを実行する。
        -- 音声やキャプチャの作業スレッドには、Luaのコールバックを登録しない。
        local ok, err = pcall(api.enumerate, parent, callback, nil)
        callback:free()
        if not ok or problem ~= nil then
            if child ~= nil then api.release(child) end
            error(problem or err)
        end
        return child
    end
    -- 列挙中にLuaへ戻るC関数の呼び出しは、LuaJITのコンパイル対象にしない。
    local has_jit, jit = pcall(require, "jit")
    if has_jit then jit.off(api.find_audio, true) end
    audio_bridge = api
    return api
end

local function open_audio_target(source, application)
    if application then
        return {
            read = function()
                local data = obs.obs_source_get_settings(source)
                if data == nil then error(T.error_audio_target) end
                local window = obs.obs_data_get_string(data, "window")
                obs.obs_data_release(data)
                return window
            end,
            write = function(window)
                local delta = obs.obs_data_create()
                if delta == nil then error(T.error_audio_data) end
                local ok, err = pcall(function()
                    obs.obs_data_set_string(delta, "window", window)
                    obs.obs_source_update(source, delta)
                end)
                obs.obs_data_release(delta)
                if not ok then error(err) end
            end,
            close = function() end,
        }
    end
    local api = initialize_audio_bridge()
    if type(obs.obs_source_get_uuid) ~= "function" then
        error(T.error_uuid_api)
    end
    local parent = api.by_name(obs.obs_source_get_name(source))
    if parent == nil then error(T.error_source_read) end
    local ok, child = pcall(function()
        if api.text(api.uuid(parent)) ~= obs.obs_source_get_uuid(source) then
            error(T.error_uuid_mismatch)
        end
        local audio = api.find_audio(parent)
        if audio == nil then error(T.error_internal_missing) end
        return audio
    end)
    api.release(parent)
    if not ok then error(child) end
    return {
        read = function()
            local data = api.settings(child)
            if data == nil then error(T.error_internal_target) end
            local window = api.text(api.get_string(data, "window"))
            api.release_data(data)
            return window
        end,
        write = function(window)
            local delta = api.create()
            if delta == nil then error(T.error_internal_data) end
            local updated, err = pcall(function()
                api.set_string(delta, "window", window)
                api.update(child, delta)
            end)
            api.release_data(delta)
            if not updated then error(err) end
        end,
        close = function() api.release(child) end,
    }
end

local function restart_audio_target(target)
    local window = target.read()
    local title, suffix = window:match("^(.-)(:.*:.*)$")
    if title == nil then
        error(T.error_target_format)
    end
    -- ウィンドウ名のタイトル部分だけを変え、直後に元へ戻す。2回の更新は、
    -- 音声ソースの同期更新を通じて、WASAPIクライアントの再起動を要求する。
    local temporary_window = (title == "" and "1" or "") .. suffix
    local ok, err = pcall(function()
        target.write(temporary_window)
        target.write(window)
        if target.read() ~= window then error(T.error_not_restored) end
    end)
    if not ok then
        -- 更新中にエラーが出ても、設定が一部変更されている可能性がある。
        -- 音源への参照を解放する前に、取り込み先を元に戻す。
        local restored, restore_error = pcall(function()
            target.write(window)
            if target.read() ~= window then error(T.error_not_restored) end
        end)
        if restored then
            error(tostring(err) .. T.restore_done)
        end
        error(tostring(err) .. T.restore_failed .. tostring(restore_error)
            .. T.restore_help)
    end
end

local function begin_refresh(on_started)
    if not loaded or exiting or collection_changing then
        return T.reset_obs_busy, obs.LOG_WARNING
    elseif refresh_in_progress then
        return T.reset_in_progress
    elseif source_name == "" then
        return T.reset_no_source, obs.LOG_WARNING
    end
    local source = obs.obs_get_source_by_name(source_name)
    if source == nil then
        return T.reset_missing_prefix .. source_name .. T.reset_missing_suffix, obs.LOG_WARNING
    end
    local name = obs.obs_source_get_name(source)
    local application = obs.obs_source_get_unversioned_id(source) == APPLICATION_AUDIO_ID
    if obs.obs_source_removed(source) or not is_target_type(source)
        or (not application and not has_audio_checkbox(source)) then
        obs.obs_source_release(source)
        return T.reset_unsupported .. name,
            obs.LOG_WARNING
    end
    if not application then
        local settings = obs.obs_source_get_settings(source)
        local enabled = obs.obs_data_get_bool(settings, AUDIO_KEY)
        obs.obs_data_release(settings)
        if not enabled then
            obs.obs_source_release(source)
            return T.reset_audio_off .. audio_checkbox_steps(name)
        end
    end
    refresh_in_progress = true
    local target
    local ok, err = pcall(function()
        target = open_audio_target(source, application)
        restart_audio_target(target)
    end)
    if target ~= nil then target.close() end
    obs.obs_source_release(source)
    refresh_in_progress = false
    if not ok then
        update_countdown()
        return failure_message(T.reset_failed .. name, err), obs.LOG_ERROR
    end
    if on_started ~= nil then on_started() end
    update_countdown()
    return T.reset_requested .. name,
        obs.LOG_INFO, true
end

local function refresh_with_log()
    local message, level, requested = begin_refresh()
    log_result(level or obs.LOG_INFO, message)
    record_result("auto", requested, true)
end


local function should_run()
    return loaded and script_enabled and not exiting and not collection_changing
        and source_name ~= ""
end

-- 画面の状態。

local function format_remaining(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor(seconds / 60) % 60
    local rest = seconds % 60
    if hours > 0 then
        return string.format(T.remaining_hours, hours, minutes, rest)
    end
    return string.format(T.remaining_minutes, minutes, rest)
end

-- Qtへの画面更新用の接続が有効な間だけ true にする。
-- その間は、残り時間の毎秒更新、見た目の調整、音源一覧の自動更新ができる。
-- 想定外のQt構成などで接続できなくても、リセット処理は動作する。
-- その場合は固定表示になるため、更新されず古くなる情報を出さない。
local function live_display()
    return ui_api ~= nil and ui_connected and ui_bridges.caption ~= nil
        and ui_bridges.sources ~= nil and not ui_updates_failed and not ui_reload_failed
end

-- 残り時間は、すでに設定されている単調時刻の期限から求める。
-- 表示のためにタイマーを開始しない。動的な文の先頭には、必ず
-- COUNTDOWN_PREFIX を付ける（下の画面更新処理で目印にする）。
countdown_caption = function()
    -- 固定表示には別の接頭辞を使い、OBS標準の再読み込みで画面が作り直されても、
    -- 保持されていた動的表示用のスタイルシートが適用されないようにする。
    if not live_display() then
        if not loaded or exiting or collection_changing then return T.static_preparing end
        if source_name == "" then return T.static_select end
        if not script_enabled then
            return follow_outputs and T.static_waiting or T.static_off
        end
        if not target_ready() then return T.static_check end
        return T.static_running
    end
    if not loaded or exiting or collection_changing then
        return COUNTDOWN_PREFIX .. T.live_preparing
    elseif source_name == "" then
        return COUNTDOWN_PREFIX .. T.live_select
    elseif not script_enabled then
        return COUNTDOWN_PREFIX .. (follow_outputs and T.live_waiting or T.live_off)
    elseif next_refresh_at == nil or not target_ready() then
        return COUNTDOWN_PREFIX .. T.live_check
    end
    local seconds = math.max(0, math.ceil((next_refresh_at - timer_time()) / 1000000000))
    return COUNTDOWN_PREFIX .. T.live_remaining .. format_remaining(seconds)
end

-- グループ内の項目では、そのグループ自身の一覧がコールバックに渡される。
-- 必要な項目は最上位の一覧から探す。取得したポインターは、
-- そのコールバック中だけ使い、後まで保持しない。
local function root_of(props)
    if type(obs.obs_properties_get_parent) ~= "function" then return props end
    local parent = obs.obs_properties_get_parent(props)
    while parent ~= nil do
        props = parent
        parent = obs.obs_properties_get_parent(props)
    end
    return props
end

local function find(props, name)
    return obs.obs_properties_get(root_of(props), name)
end

sync_controls = function(props)
    local manual = find(props, "test_now")
    if manual ~= nil then
        -- 開いた画面の自動更新が途中で止まっても、ボタンは常に押せるようにする。
        -- 音声を操作する前の準備確認は、begin_refresh が行う。
        obs.obs_property_set_enabled(manual, true)
    end
    -- 画面の構築時と設定変更時だけ実行し、表示用タイマーからは呼ばない。
    -- そのため、音源に音声設定があるかも含めた詳しい確認を行える。
    update_notice(true)
end

-- OBS標準のボタン処理で表示内容を作り直せば、Qtへの接続に依存せず復旧できる。
-- この復旧経路は、いつでも使えるようにしておく。
local function refresh_view(props)
    if not loaded or exiting or collection_changing then return false end
    ui_updates_failed = false
    ui_reload_failed = false
    ui_api_attempted = ui_api ~= nil
    configure_script_view()
    local dropdown = find(props, "source_name")
    if dropdown ~= nil then populate_sources(dropdown) end
    sources_dirty = false
    return true
end

-- Qtを使った画面更新。

local function initialize_ui_api()
    if ui_api_attempted then return ui_api end
    ui_api_attempted = true
    local ok, result = pcall(function()
        local ffi = require("ffi")
        if ffi.os ~= "Windows" or not ffi.abi("64bit") then error(T.error_ui_windows) end
        if not pcall(ffi.typeof, "obs_aar_qstring") then
            ffi.cdef[[typedef struct { void *d, *data; intptr_t size; } obs_aar_qstring;]]
        end
        if not pcall(ffi.typeof, "obs_aar_qargument") then
            ffi.cdef[[
                typedef struct { const void *data; const char *name; } obs_aar_qargument;
                void * __stdcall GetModuleHandleA(const char *);
                void * __stdcall GetProcAddress(void *, const char *);
                int __stdcall MultiByteToWideChar(unsigned int, unsigned long, const char *, int,
                    unsigned short *, int);
                void * __stdcall GetTopWindow(void *);
                void * __stdcall GetWindow(void *, unsigned int);
                unsigned long __stdcall GetWindowThreadProcessId(void *, unsigned long *);
                unsigned long __stdcall GetCurrentProcessId(void);
            ]]
        end
        local kernel = ffi.load("kernel32")
        local core = kernel.GetModuleHandleA("Qt6Core.dll")
        local widgets = kernel.GetModuleHandleA("Qt6Widgets.dll")
        if core == nil or widgets == nil then error(T.error_ui_connection) end
        local function address(module, name)
            local value = kernel.GetProcAddress(module, name)
            if value == nil then error(T.error_ui_api .. name) end
            return value
        end
        local function method(module, name, signature)
            return ffi.cast(signature, address(module, name))
        end
        return {
            ffi = ffi, kernel = kernel, user = ffi.load("user32"),
            pid = tonumber(kernel.GetCurrentProcessId()),
            find = method(widgets, "?find@QWidget@@SAPEAV1@_K@Z", "void *(*)(uintptr_t)"),
            style_sheet = method(widgets, "?setStyleSheet@QWidget@@QEAAXAEBVQString@@@Z", "void (*)(void *, const void *)"),
            qstring = method(core, "??0QString@@QEAA@PEBVQChar@@_J@Z", "void (*)(void *, const unsigned short *, intptr_t)"),
            assign = method(core, "??4QString@@QEAAAEAV0@AEBV0@@Z", "void *(*)(void *, const void *)"),
            child = method(core,
                "?qt_qFindChild_helper@@YAPEAVQObject@@PEBV1@AEBVQString@@AEBUQMetaObject@@V?$QFlags@W4FindChildOption@Qt@@@@@Z",
                "void *(*)(const void *, const void *, const void *, int)"),
            connect = method(core,
                "?connect@QObject@@SA?AVConnection@QMetaObject@@PEBV1@PEBD01W4ConnectionType@Qt@@@Z",
                "void *(*)(void *, const void *, const char *, const void *, const char *, int)"),
            release_connection = method(core, "??1Connection@QMetaObject@@QEAA@XZ", "void (*)(void *)"),
            disconnect = method(core, "?disconnect@QObject@@SA_NPEBV1@PEBD01@Z",
                "bool (*)(const void *, const char *, const void *, const char *)"),
            create_object = method(core, "?newInstance@QMetaObject@@QEBAPEAVQObject@@VQGenericArgument@@000000000@Z",
                "void *(*)(const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *)"),
            delete_later = method(core, "?deleteLater@QObject@@QEAAXXZ", "void (*)(void *)"),
            invoke = method(core,
                "?invokeMethod@QMetaObject@@SA_NPEAVQObject@@PEBDW4ConnectionType@Qt@@VQGenericReturnArgument@@VQGenericArgument@@444444444@Z",
                "bool (*)(void *, const char *, int, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *, const void *)"),
            object_meta = address(core, "?staticMetaObject@QObject@@2UQMetaObject@@B"),
            scroll_meta = address(widgets, "?staticMetaObject@QScrollArea@@2UQMetaObject@@B"),
            empty_string = ffi.new("obs_aar_qstring[1]"),
            empty_argument = ffi.new("obs_aar_qargument[1]")
        }
    end)
    if ok then ui_api = result
    else fail_ui(result) end
    return ui_api
end

local function ui_string(qt, text)
    local value = qt.ffi.new("obs_aar_qstring[1]")
    if text ~= "" then
        local length = qt.kernel.MultiByteToWideChar(65001, 8, text, #text, nil, 0)
        if length <= 0 then error(T.error_ui_encoding) end
        local wide = qt.ffi.new("unsigned short[?]", length)
        if qt.kernel.MultiByteToWideChar(65001, 8, text, #text, wide, length) ~= length then
            error(T.error_ui_encoding)
        end
        qt.qstring(value, wide, length)
    end
    return value
end

-- 最初の表示と、その後の更新要求で、同じスタイルシートの作成処理を使う。
-- ボタンの文は固定し、ここでは幅だけを設定する。
local BUTTON_SELECTOR = 'QPushButton[text="' .. MANUAL_CAPTION .. '"]'
-- 残り時間の行だけが、この接頭辞で始まるラベルになる。
local COUNTDOWN_SELECTOR = 'QLabel[text^="' .. COUNTDOWN_PREFIX .. '"]'
local STATIC_COUNTDOWN_SELECTOR = 'QLabel[text^="' .. T.static_prefix .. '"]'
-- 「設定」と「状態」でラベル幅をそろえ、入力欄の位置を合わせる。
-- 英語表示では「Interval (min)」や状態メッセージのために、より広い幅を確保する。
local LABEL_COLUMN_WIDTH = USE_JAPANESE and "3em" or "6.5em"
local VIEW_MIN_WIDTH = USE_JAPANESE and "16.5em" or "24em"
local ROW_LABELS = 'QLabel[text="' .. LABEL.source .. '"], QLabel[text="' .. LABEL.interval .. '"], '
    .. 'QLabel[text="' .. LABEL.mode .. '"], QLabel[text="' .. LABEL.countdown .. '"], '
    .. 'QLabel[text="' .. LABEL.notice .. '"]'
-- 両グループと説明欄が収まるよう、高さを確保する。最小値は27e。、
-- 説明欄だけに最小の高さを指定すると、外側のスクロール領域が中身より小さくなってしまう。
-- 画面全体の最小サイズは、OBSの配置処理を通じてスクリプト画面にも反映される。
-- ウィンドウを大きくした分は、説明欄が縦方向に伸びて受け持つ。
-- 文字サイズに応じた単位を使い、利用者の表示倍率に追従させる。
-- 各言語で、最長の残り時間と5行分の状態表示が収まる幅を確保する。
local VIEW_STYLE =
    'OBSPropertiesView { min-width: ' .. VIEW_MIN_WIDTH .. '; min-height: 27em; } '
    .. '.IconLabel { min-width: 0px; max-width: 0px; min-height: 0px; max-height: 0px; padding: 0px; margin: 0px; border: none; } '
    -- 最大幅も明示し、OBSでサイズ方針が Maximum のボタンを行いっぱいに広げる。
    .. BUTTON_SELECTOR .. ' { text-align: center; max-width: 1000000px; } '
    .. COUNTDOWN_SELECTOR .. ', ' .. STATIC_COUNTDOWN_SELECTOR .. ' { qproperty-alignment: AlignCenter; margin: 0px; padding: 7px 0px; '
    .. 'border-radius: 4px; background-color: palette(button); color: palette(button-text); } '
    -- 読み取り専用の指定もここで行い、Qtへの追加接続は増やさない。
    -- 標準の複数行欄は、縦方向の伸縮と文字のコピーに対応している。
    -- スタイルシートが適用されなくても、欄が編集可能になるだけで処理に支障はない。
    .. 'QPlainTextEdit { qproperty-readOnly: true; min-height: 6em; } '
    -- 長い音源名は、画面全体の幅を広げず、選択欄の中で省略表示できるようにする。
    -- 開いた選択肢の一覧には、音源名を省略せず表示する。
    .. 'QComboBox { min-width: 0px; qproperty-minimumContentsLength: 8; '
    .. 'qproperty-sizeAdjustPolicy: AdjustToMinimumContentsLengthWithIcon; } '
    -- 2つのグループは別々のフォームなので、通常は各ラベルに応じて列幅が決まる。
    -- 両方のラベルに同じ最小幅を設定し、文が違っていても、
    -- グループ間で入力欄の開始位置がそろうようにする。
    -- 幅の単位は em とし、文字サイズに追従させる。
    .. ROW_LABELS .. ' { min-width: ' .. LABEL_COLUMN_WIDTH .. '; } '

local function view_style(caption)
    if caption == nil then return VIEW_STYLE end
    local quoted = caption:gsub("\\", "\\\\"):gsub('"', '\\"')
    return VIEW_STYLE
        .. COUNTDOWN_SELECTOR .. ' { qproperty-text: "' .. quoted .. '"; }'
end

configure_script_view = function()
    if type(obs.obs_in_task_thread) == "function" and obs.OBS_TASK_UI ~= nil
        and not obs.obs_in_task_thread(obs.OBS_TASK_UI) then return end
    local qt = initialize_ui_api()
    if qt == nil then return end
    ui_connected = false
    local ok, err = pcall(function()
        local name = ui_string(qt, "scripts")
        local view, checked = nil, 0
        local pid = qt.ffi.new("unsigned long[1]")
        local hwnd = qt.user.GetTopWindow(nil)
        -- ScriptsTool は親を持たない QDialog。プロパティの構築時に画面用の
        -- スレッドからだけ探し、表示用タイマーからは探さない。
        while hwnd ~= nil and checked < 4096 do
            qt.user.GetWindowThreadProcessId(hwnd, pid)
            if tonumber(pid[0]) == qt.pid then
                local root = qt.find(qt.ffi.cast("uintptr_t", hwnd))
                if root ~= nil and qt.child(root, name, qt.object_meta, 1) ~= nil then
                    view = qt.child(root, qt.empty_string, qt.scroll_meta, 1)
                    if view ~= nil then break end
                end
            end
            hwnd = qt.user.GetWindow(hwnd, 2)
            checked = checked + 1
        end
        qt.assign(name, qt.empty_string)
        if view == nil then return end
        -- 2種類の更新はQt自身が順に処理する。画面部品のポインターは保持しない。
        if not ui_updates_failed then
            for _, entry in ipairs({{"caption", "1setStyleSheet(QString)"}, {"sources", "1ReloadProperties()"}}) do
                local key, slot = entry[1], entry[2]
                if ui_bridges[key] == nil then
                    local e = qt.empty_argument
                    ui_bridges[key] = qt.create_object(qt.object_meta, e, e, e, e, e, e, e, e, e, e)
                    if ui_bridges[key] == nil then error(T.error_ui_create) end
                end
                -- プロパティを繰り返し読み込む際、同じ受信先が再利用される場合がある。
                -- 自分の通知を接続し直し、すでに接続されているというだけで、
                -- UniqueConnection の接続確認を失敗と判断しないようにする。
                qt.disconnect(ui_bridges[key], "2objectNameChanged(QString)", view, slot)
                local connection = qt.ffi.new("void *[1]")
                qt.connect(connection, ui_bridges[key], "2objectNameChanged(QString)", view, slot, 128)
                local connected = connection[0] ~= nil
                qt.release_connection(connection)
                if not connected then error(T.error_ui_connect .. key) end
            end
            ui_connected = true
        end
        local style = ui_string(qt, view_style(live_display() and countdown_caption() or nil))
        qt.style_sheet(view, style)
        qt.assign(style, qt.empty_string)
        last_countdown_text = nil
    end)
    if not ok then fail_ui(err) end
end

local function post_ui(bridge, text)
    local qt = ui_api
    local argument = qt.ffi.new("obs_aar_qargument[1]")
    argument[0].data, argument[0].name = text, "QString"
    local e = qt.empty_argument
    return qt.invoke(bridge, "objectNameChanged", 2, e, argument, e, e, e, e, e, e, e, e, e)
end

update_countdown = function()
    if not live_display() or not loaded or exiting then return end
    local qt, value = ui_api, nil
    local ok, err = pcall(function()
        local caption = countdown_caption()
        if caption == last_countdown_text then return end
        value = ui_string(qt, view_style(caption))
        -- QueuedConnection は QString をコピーする。画面用スレッドではQtの処理だけを動かし、
        -- Luaのタイマーから QWidget を直接読み書きしない。
        if not post_ui(ui_bridges.caption, value) then
            error(T.error_ui_post)
        end
        last_countdown_text = caption
    end)
    if value ~= nil then qt.assign(value, qt.empty_string) end
    if not ok then fail_ui(err) end
end

countdown_tick = function()
    update_countdown()
    -- 音源を定期走査せず、既存のタイマーで複数の音源変更通知をまとめて処理する。
    if sources_dirty and loaded and not exiting and not collection_changing
        and ui_api ~= nil and ui_bridges.sources ~= nil and not ui_reload_failed then
        local ok, posted = pcall(post_ui, ui_bridges.sources, ui_api.empty_string)
        if ok and posted then sources_dirty = false
        else
            ui_reload_failed = true
            fail_ui(ok and T.error_source_reload or posted)
        end
    end
end

local function close_ui_bridge()
    for _, bridge in pairs(ui_bridges) do
        ui_api.disconnect(bridge, nil, nil, nil)
        ui_api.delete_later(bridge)
    end
    ui_bridges = {}
    ui_connected = false
end

-- 実行間隔の管理と、音源・OBS本体からの通知。

local function interval_callback()
    if should_run() then
        -- OBSの繰り返しタイマーは、呼び出し時刻ではなく設定した周期ごとに進む。
        next_refresh_at = (next_refresh_at or timer_time()) + interval_minutes * 60 * 1000000000
        refresh_with_log()
    else
        obs.timer_remove(interval_callback)
        next_refresh_at = nil
    end
    update_countdown()
end

local function restart_interval_timer()
    obs.timer_remove(interval_callback)
    next_refresh_at = nil
    if should_run() then
        -- 自動動作の開始から、選んだ間隔がすべて経過したあとに最初のリセットを行う。
        next_refresh_at = timer_time() + interval_minutes * 60 * 1000000000
        obs.timer_add(interval_callback, interval_minutes * 60 * 1000)
    end
    update_countdown()
end

local function manual_refresh_button(props, property)
    -- 音源が準備できていれば、自動動作の設定に関係なく手動リセットできる。
    local message, level, requested = begin_refresh(restart_interval_timer)
    -- 処理の完了は、設定を元に戻して再起動を要求できたという意味。
    -- 実際に音声の再接続が完了したことまでは確認していない。
    -- 説明欄の高さを変えないよう表示は短くし、詳しい理由はログに残す。
    -- ボタンを常に押せるため、音源を利用できない場合もここで結果を記録する。
    log_result(level or obs.LOG_WARNING, message)
    record_result("manual", requested, true)
    event_note = nil
    -- 表示が固まるとボタンが押されやすいため、案内を増やさず復旧を試みる。
    -- 音源一覧と画面更新の接続を再読み込みする。正常なら表示は変わらない。
    refresh_view(props)
    update_notice(true)
    return true
end

local function source_list_changed(cd)
    if not loaded or exiting or collection_changing then return end
    local source = obs.calldata_source(cd, "source")
    if source == nil or not is_target_type(source) then return end
    if source_uuid == nil and obs.obs_source_get_name(source) == source_name then
        source_uuid = obs.obs_source_get_uuid(source)
    end
    sources_dirty = true
    return source
end

local function source_renamed(cd)
    local source = source_list_changed(cd)
    if source ~= nil and obs.obs_source_get_uuid(source) == source_uuid then
        source_name = obs.obs_source_get_name(source)
        obs.obs_data_set_string(saved_settings, "source_name", source_name)
    end
end

local function source_disappeared(cd)
    local source = source_list_changed(cd)
    if source ~= nil and obs.obs_source_get_uuid(source) == source_uuid then
        source_name, source_uuid = "", nil
        obs.obs_data_set_string(saved_settings, "source_name", "")
        restart_interval_timer()
        event_note = T.source_removed
        last_result = nil
        update_notice()
    end
end

local function source_settings_changed(cd)
    if not loaded or exiting or collection_changing or refresh_in_progress then return end
    local source = obs.calldata_source(cd, "source")
    if source ~= nil and obs.obs_source_get_uuid(source) == source_uuid then sources_dirty = true end
end

local function watch_sources(connect)
    local handler = obs.obs_get_signal_handler()
    local action = connect and obs.signal_handler_connect or obs.signal_handler_disconnect
    for signal, callback in pairs({source_create = source_list_changed, source_remove = source_disappeared,
        source_destroy = source_disappeared, source_rename = source_renamed, source_update = source_settings_changed}) do
        action(handler, signal, callback)
    end
end

local function sync_linked_power(restart_timer)
    if not loaded or not follow_outputs or exiting or collection_changing or saved_settings == nil then return end
    local enabled = output_active()
    if enabled == script_enabled then return end
    script_enabled = enabled
    obs.obs_data_set_bool(saved_settings, "script_enabled", enabled)
    last_countdown_text = nil
    event_note = nil
    update_notice()
    sources_dirty = true
    if restart_timer ~= false then restart_interval_timer() end
end

local function on_frontend_event(event)
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED
        or event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED
        or event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED
        or event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        sync_linked_power()
    elseif event == obs.OBS_FRONTEND_EVENT_SCENE_COLLECTION_CHANGING then
        collection_changing = true
        source_uuid = nil
        obs.timer_remove(interval_callback)
        next_refresh_at = nil
        update_countdown()
    elseif event == obs.OBS_FRONTEND_EVENT_SCENE_COLLECTION_CHANGED
        or event == obs.OBS_FRONTEND_EVENT_FINISHED_LOADING then
        collection_changing = false
        sync_linked_power(false)
        track_source()
        event_note = nil
        update_notice()
        sources_dirty = true
        restart_interval_timer()
    elseif event == obs.OBS_FRONTEND_EVENT_EXIT then
        exiting = true
        obs.timer_remove(interval_callback)
        obs.timer_remove(countdown_tick)
        next_refresh_at = nil
        close_ui_bridge()
    end
end

-- OBSから呼び出される関数。

function script_description()
    local title = T.title_prefix .. VERSION .. "</b><br>"
    local problem, warning = compatibility()
    if problem ~= nil then
        -- この環境では以降の処理が動かないため、使い方の代わりに理由を表示する。
        return title .. "<b>⚠ " .. problem:gsub("\n", "<br>") .. "</b>"
    end
    local text = title:gsub("<br>$", "")
    if warning ~= nil then
        text = text .. "<br><b>⚠ " .. warning:gsub("\n", "<br>") .. "</b>"
    end
    return text
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "source_name", "")
    obs.obs_data_set_default_int(settings, "interval_minutes", 30)
    obs.obs_data_set_default_string(settings, "mode", "outputs")
end

function script_properties()
    local props = obs.obs_properties_create()
    -- この場合は、script_description() の説明だけを画面に表示する。
    if compatibility() ~= nil then return props end
    configure_script_view()
    local function changed(p, property, settings)
        return settings_modified(p, settings)
    end

    -- 下の2つの欄は構築時に設定データを読むため、先に表示内容を書き込む。
    update_notice(true)

    -- 設定グループには変更可能な項目をまとめ、その下にリセットボタンを置く。
    local config = obs.obs_properties_create()
    obs.obs_properties_add_group(props, "settings_group", LABEL.settings_group, obs.OBS_GROUP_NORMAL, config)
    local dropdown = obs.obs_properties_add_list(config, "source_name", LABEL.source,
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    populate_sources(dropdown)
    sources_dirty = false
    obs.obs_property_set_modified_callback(dropdown, changed)
    local timer = obs.obs_properties_add_int(config, "interval_minutes", LABEL.interval,
        MIN_TIMER_MINUTES, MAX_TIMER_MINUTES, 1)
    -- ここには変更通知を登録しない。通知が true を返すとOBSが画面を作り直し、
    -- 数字を1文字入力するたびに入力欄から選択が外れるため。script_update は
    -- 変更のたびに呼ばれるので、表示文には間隔の値を埋め込まない。
    local mode = obs.obs_properties_add_list(config, "mode", LABEL.mode,
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    for _, key in ipairs(MODE_ORDER) do
        obs.obs_property_list_add_string(mode, MODE_LABEL[key], key)
    end
    obs.obs_property_set_modified_callback(mode, changed)
    obs.obs_properties_add_button(config, "test_now", MANUAL_CAPTION, manual_refresh_button)

    -- 状態グループには、毎秒更新する残り時間の行と、
    -- 現在の状態・必要な操作を説明する欄を置く。
    local status = obs.obs_properties_create()
    obs.obs_properties_add_group(props, "status_group", LABEL.status_group, obs.OBS_GROUP_NORMAL, status)
    local countdown = obs.obs_properties_add_text(status, "countdown", LABEL.countdown, obs.OBS_TEXT_INFO)
    obs.obs_property_text_set_info_word_wrap(countdown, false)
    obs.obs_properties_add_text(status, "notice", LABEL.notice, obs.OBS_TEXT_MULTILINE)

    for key, help in pairs(HELP) do
        local property = find(props, key)
        if property ~= nil then obs.obs_property_set_long_description(property, help) end
    end
    sync_controls(props)
    return props
end

function script_update(settings)
    if compatibility() ~= nil then return end
    local new_name = obs.obs_data_get_string(settings, "source_name")
    local new_interval = math.max(MIN_TIMER_MINUTES,
        math.min(MAX_TIMER_MINUTES, obs.obs_data_get_int(settings, "interval_minutes")))
    -- 内部で使う値と画面の値を、対応する範囲内に収める。
    obs.obs_data_set_int(settings, "interval_minutes", new_interval)
    -- 動作の選択値から、内部の2つのフラグを決める。
    local mode = obs.obs_data_get_string(settings, "mode")
    if mode ~= "always" and mode ~= "off" then mode = "outputs" end
    local new_follow = mode == "outputs"
    local new_enabled = mode == "always" or (new_follow and output_active())
    local enabled_changed = new_enabled ~= script_enabled
    if enabled_changed then last_countdown_text = nil end
    local source_changed = new_name ~= source_name
    local changed = source_changed or new_interval ~= interval_minutes or enabled_changed
    source_name = new_name
    interval_minutes = new_interval
    script_enabled = new_enabled
    follow_outputs = new_follow
    if changed then event_note = nil end
    if source_changed then
        track_source()
        last_result = nil
    end
    if changed and loaded then
        restart_interval_timer()
    end
    obs.obs_data_set_string(settings, "notice", status_text(false))
    obs.obs_data_set_string(settings, "countdown", countdown_caption())
end

-- 従来のチェックボックス設定を、一度だけ動作の選択値へ移行する。
-- 移行前と同じ動作になるようにする。
local function migrate_mode(settings)
    if obs.obs_data_has_user_value(settings, "mode") then return end
    local has_follow = obs.obs_data_has_user_value(settings, "follow_outputs")
    local has_enabled = obs.obs_data_has_user_value(settings, "script_enabled")
    if not has_follow and not has_enabled then return end
    local mode = "off"
    if obs.obs_data_get_bool(settings, "follow_outputs") then
        mode = "outputs"
    elseif obs.obs_data_get_bool(settings, "script_enabled") then
        mode = "always"
    end
    obs.obs_data_set_string(settings, "mode", mode)
end

function script_load(settings)
    log_result(obs.LOG_INFO, string.format(T.version_log, VERSION))
    local problem = compatibility()
    if problem ~= nil then
        -- タイマーも通知の受け取りも開始しない。理由は script_description() に表示する。
        obs.script_log(obs.LOG_WARNING, (problem:gsub("[\r\n]+", " / ")))
        return
    end
    obs.obs_data_addref(settings)
    saved_settings = settings
    exiting = false
    collection_changing = false
    migrate_mode(settings)
    obs.obs_frontend_add_event_callback(on_frontend_event)
    -- リセット用と表示用のタイマーを開始する前に、設定を適用する。
    script_update(settings)
    loaded = true
    watch_sources(true)
    restart_interval_timer()
    ui_updates_failed = false
    ui_reload_failed = false
    obs.timer_add(countdown_tick, COUNTDOWN_UPDATE_MS)
end

function script_save(settings)
    if compatibility() ~= nil then return end
    -- 旧版と上の設定移行処理が読めるよう、従来の設定項目も残す。
    obs.obs_data_set_bool(settings, "script_enabled", script_enabled)
    obs.obs_data_set_bool(settings, "follow_outputs", follow_outputs)
end

function script_unload()
    loaded = false
    exiting = true
    watch_sources(false)
    obs.timer_remove(interval_callback)
    next_refresh_at = nil
    obs.timer_remove(countdown_tick)
    close_ui_bridge()
    obs.obs_frontend_remove_event_callback(on_frontend_event)
    if saved_settings ~= nil then
        obs.obs_data_release(saved_settings)
        saved_settings = nil
    end
end
