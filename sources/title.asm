; title.asm - タイトル
;

; モジュールの宣言
;
    module  title


; ファイルの参照
;
    include "xcs.inc"
    include "app.inc"
    include "title.inc"
    include "resources/sounds/song.inc"


; コードの定義
;
    section app

; プログラムのエントリポイント
;
_title_entry:

    ; 処理の設定
    ld      hl, title_update
    ld      (_app_proc), hl
    xor     a
    ld      (_app_state), a

; タイトルを更新する
;
title_update:

    ; 初期化
    ld      a, (_app_state)
    or      a
    jr      nz, title_update_initialize_end

    ; カーソルの設定
    ld      de, TITLE_CURSOR_YX
    call    _xcs_calc_text_attribute_0
    ld      a, XCS_IO_TEXT_ATTRIBUTE_PCG | XCS_IO_TEXT_ATTRIBUTE_BLINK | XCS_IO_TEXT_ATTRIBUTE_WHITE
    out     (c), a

    ; 初期化の完了
    ld      hl, _app_state
    inc     (hl)
.title_update_initialize_end

    ; 1: キー入力待ち
.title_update_1
    ld      a, (_app_state)
    cp      $01
    jr      nz, title_update_2

    ; キー入力
    ld      a, (_xcs_controller_edge)
    and     XCS_IO_STICK_A | XCS_IO_STICK_B
    jr      z, title_update_end

    ; カーソルのクリア
    ld      de, TITLE_CURSOR_YX
    call    _xcs_calc_text_attribute_0
    ld      a, XCS_IO_TEXT_ATTRIBUTE_PCG | XCS_IO_TEXT_ATTRIBUTE_WHITE
    out     (c), a

    ; 文字列の描画
    ld      de, TITLE_CURSOR_YX
    ld      hl, title_update_string
    call    _xcs_print_string

    ; カーソルの設定
    ld      de, TITLE_CURSOR_YX + $0003
    call    _xcs_calc_text_attribute_0
    ld      a, XCS_IO_TEXT_ATTRIBUTE_PCG | XCS_IO_TEXT_ATTRIBUTE_BLINK | XCS_IO_TEXT_ATTRIBUTE_WHITE
    out     (c), a

    ; BGM の再生
    ld      a, SONG_PIPO
    ld      c, $00
    call    _xcs_play_bgm

    ; 処理の更新
    ld      hl, _app_state
    inc     (hl)
    jr      title_update_end

    ; 2: サウンド待ち
.title_update_2

    ; サウンドの監視
    call    _xcs_is_play_bgm
    or      a
    jr      nz, title_update_end

    ; カーソルのクリア
    ld      de, TITLE_CURSOR_YX + $0003
    call    _xcs_calc_text_attribute_0
    ld      a, XCS_IO_TEXT_ATTRIBUTE_PCG | XCS_IO_TEXT_ATTRIBUTE_WHITE
    out     (c), a

    ; 処理の設定
    ld      hl, _game_entry
    ld      (_app_proc), hl
    xor     a
    ld      (_app_state), a
;   jr      title_update_end

    ; 終了
.title_update_end
    ret

; 文字列
.title_update_string
    defb    "RUN", $00
