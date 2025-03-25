; app.asm - アプリケーション
;

; モジュールの宣言
;
    module  app


; ファイルの参照
;
    include "xcs.inc"
    include "app.inc"


; コードの定義
;
    section app

; プログラムのエントリポイント
;
    org     XCS_APP_START

app_entry:

    ; グラフィックを前面に設定
    call    _xcs_set_priority_front

    ; カウンタの初期化
    xor     a
    ld      (app_counter), a

    ; 起動画面の描画
    ld      de, $0000
    ld      hl, app_string_boot
    call    _xcs_print_string

    ; PCG の定義
    ld      de, app_pcg
    call    _xcs_load_pcg

    ; サウンドの定義
    ld      de, app_sound
    call    _xcs_load_sound

    ; OK の描画
    ld      de, $0300
    ld      hl, app_string_ok
    call    _xcs_print_string

    ; 処理の設定
    ld      hl, _title_entry
    ld      (_app_proc), hl
    xor     a
    ld      (_app_state), a

; アプリケーションを更新する
;
app_update:

    ; XCS の更新
    call    _xcs_update

    ; 処理の更新
    ld      hl, (_app_proc)
    ld      a, h
    or      l
    jr      z, app_update_next
    ld      de, app_update_next
    push    de
    jp      (hl)
.app_update_next

    ; カウンタの更新
    ld      a, (app_counter)
    add     a, $01
    daa
    cp      $60
    jr      c, app_update_count
    xor     a
.app_update_count
    ld      (app_counter), a

;   ; カウンタの表示
;   ld      a, (app_counter)
;   ld      de, $0000
;   call    _xcs_print_hex_chars
    ld      a, (app_counter)
    ld      de, $0000
    call    _xcs_debug_print_hex_chars

    ; 垂直帰線期間の終了を待つ
    call    _xcs_wait_v_dsip_off

    ; 繰り返し
    jr      app_update

; 処理
;
_app_proc:
    defs    $02

; 状態
;
_app_state:
    defs    $01

; カウンタ
;
.app_counter
    defs    $01

; PCG
;
.app_pcg
    incbin  "resources/pcgs/bg.pcg"

; サウンド
;
.app_sound
    incbin  "resources/sounds/song.snd"

; 文字列
;
.app_string_boot
    defb    "NS-HUBASIC V2.1A\n"
    defb    $b4, " NINTENDO/SHARP/HUDSON\n"
    defb    "1982 BYTES FREE"
    defb    $00
.app_string_ok
    defb    "OK"
    defb    $00


