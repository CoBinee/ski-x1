; game.asm - ゲーム
;

; モジュールの宣言
;
    module  game


; ファイルの参照
;
    include "xcs.inc"
    include "app.inc"
    include "game.inc"
    include "resources/sounds/song.inc"


; コードの定義
;
    section app

; プログラムのエントリポイント
;
_game_entry:

    ; テキストのクリア
    ld      d, ' '
    call    _xcs_clear_text_vram_0

    ; グラフィックのクリア
    ld      d, $00
    call    _xcs_clear_graphic_vram

    ; ゲームの初期化
    ld      hl, $0000
    ld      (game_score), hl

    ; 道の初期化
    call    game_initialize_road

    ; ペンペンの初期化
    call    game_initialize_penpen

    ; 処理の設定
    ld      hl, game_play
    ld      (_app_proc), hl
    xor     a
    ld      (_app_state), a

    ; 終了
    ret

; ゲームをプレイする
;
game_play:

    ; 初期化
    ld      a, (_app_state)
    or      a
    jr      nz, game_play_initialize_end

    ; フレームの初期化
    ld      a, $01
    ld      (game_play_frame), a

    ; BGM の再生
    ld      a, SONG_BGM
    ld      c, $ff
    call    _xcs_play_bgm

    ; 初期化の完了
    ld      hl, _app_state
    inc     (hl)
.game_play_initialize_end

    ; フレームの監視
    ld      hl, game_play_frame
    dec     (hl)
    jr      nz, game_play_end
    ld      (hl), GAME_FRAME_INTERVAL

    ; 道の更新
    call    game_update_road

    ; ペンペンの更新
    call    game_update_penpen

    ; 道の描画
    call    game_draw_road

    ; ペンペンの描画
    call    game_draw_penpen

    ; ゲームオーバーの判定
    ld      a, (game_penpen_x)
    ld      e, a
    ld      a, (game_road_locate + GAME_PENPEN_Y)
    add     a, GAME_ROAD_SAFETY_LEFT - $01
    cp      e
    jr      nc, game_play_over
    add     a, GAME_ROAD_SAFETY_RIGHT - GAME_ROAD_SAFETY_LEFT + $01
    cp      e
    jr      nc, game_play_end

    ; ゲームオーバー
.game_play_over

    ; 処理の設定
    ld      hl, game_over
    ld      (_app_proc), hl
    xor     a
    ld      (_app_state), a

    ; 終了
.game_play_end
    ret

; フレーム
.game_play_frame
    defs    $01

; ゲームオーバーになる
;
game_over:

    ; 初期化
    ld      a, (_app_state)
    or      a
    jr      nz, game_over_initialize_end

    ; BGM の停止
    call    _xcs_stop_bgm

    ; BGM の再生
    ld      a, SONG_MISS
    ld      c, $00
    call    _xcs_play_bgm

    ; 初期化の完了
    ld      hl, _app_state
    inc     (hl)
.game_over_initialize_end

    ; 1: サウンドの再生待ち
.game_over_1
    ld      a, (_app_state)
    cp      $01
    jr      nz, game_over_2

    ; サウンドの監視
    call    _xcs_is_play_bgm
    or      a
    jr      nz, game_over_end

    ; スコアの表示
    ld      de, (game_score)
    call    _xcs_get_decimal_string_left
    ld      c, $00
    push    hl
.game_over_1_score_length
    ld      a, (hl)
    or      a
    jr      z, game_over_1_score_draw
    inc     hl
    inc     c
    jr      game_over_1_score_length
.game_over_1_score_draw
    pop     hl
    push    bc
    ld      de, $0c0d
    call    _xcs_print_string
    pop     bc
    ld      a, c
    add     a, $0d
    ld      e, a
    ld      d, $0c
    ld      hl, game_over_string_score
    call    _xcs_print_string

    ; 評価の表示
    ld      de, (game_score)
    ld      hl, 100 - 1
    or      a
    sbc     hl, de
    jr      c, game_over_1_eval_1
    ld      hl, game_over_string_eval_0
    jr      game_over_1_eval_draw
.game_over_1_eval_1
    ld      hl, 500 - 1
    or      a
    sbc     hl, de
    jr      c, game_over_1_eval_2
    ld      hl, game_over_string_eval_1
    jr      game_over_1_eval_draw
.game_over_1_eval_2
    ld      hl, 1000 - 1
    or      a
    sbc     hl, de
    jr      c, game_over_1_eval_3
    ld      hl, game_over_string_eval_2
    jr      game_over_1_eval_draw
.game_over_1_eval_3
    ld      a, SONG_CONGRATULATION
    ld      c, $00
    call    _xcs_play_bgm
    ld      hl, game_over_string_eval_3
;   jr      game_over_1_eval_draw
.game_over_1_eval_draw
    ld      de, $0d0d
    call    _xcs_print_string

    ; 処理の更新
    ld      hl, _app_state
    inc     (hl)
    jr      game_over_end

    ; 2: キー入力待ち
.game_over_2

    ; サウンドの監視
    call    _xcs_is_play_bgm
    or      a
    jr      nz, game_over_end

    ; キー入力
    ld      a, (_xcs_controller_edge)
    and     XCS_IO_STICK_A | XCS_IO_STICK_B
    jr      z, game_over_end

    ; 処理の設定
    ld      hl, _game_entry
    ld      (_app_proc), hl
    xor     a
    ld      (_app_state), a

    ; 終了
.game_over_end
    ret

; 文字列
.game_over_string_score
    defb    $81, $2d, $73, $88, $a1, $85, $21, $00
.game_over_string_eval_0
    defb    $6a, $61, $72, $2d, $21, $00
.game_over_string_eval_1
    defb    "GOOD!", $00
.game_over_string_eval_2
    defb    $6a, $61, $69, $2d, $21, $00
.game_over_string_eval_3
    defb    "CONGRATULATION!", $00

; ゲームデータ
;
.game_score
    defs    $02

; 道を初期化する
;
.game_initialize_road

    ; 配置の設定
    ld      hl, game_road_locate + $0000
    ld      de, game_road_locate + $0001
    ld      bc, GAME_ROAD_SIZE - $0001
    ld      (hl), $ff
    ldir

    ; 経路の設定
    ld      hl, game_road_route + $0000
    ld      de, game_road_route + $0001
    ld      bc, GAME_ROAD_SIZE - $0001
    ld      (hl), $ff
    ldir

    ; 位置の設定
    ld      a, GAME_ROAD_START_X
    ld      (game_road_x), a
    ld      a, GAME_ROAD_START_Y - $01
    ld      (game_road_y), a

    ; 終了
    ret

; 道を更新する
;
.game_update_road

    ; スクロール
    ld      a, (game_road_y)
    cp      GAME_ROAD_SIZE - $01
    jr      nc, game_update_road_scroll
    inc     a
    ld      (game_road_y), a
    jr      game_update_road_scroll_end
.game_update_road_scroll
    ld      hl, game_road_locate + $0001
    ld      de, game_road_locate + $0000
    ld      bc, GAME_ROAD_SIZE - $0001
    ldir
    ld      hl, game_road_route + $0001
    ld      de, game_road_route + $0000
    ld      bc, GAME_ROAD_SIZE - $0001
    ldir
    ld      hl, game_score
    inc     (hl)
.game_update_road_scroll_end

    ; 新しい道の作成
    ld      a, (game_road_y)
    ld      e, a
    ld      d, $00
    ld      hl, game_road_locate - $0001
    add     hl, de
    cp      GAME_ROAD_STRAIGHT_Y
    jr      nc, game_update_road_new
    ld      a, GAME_ROAD_START_X
    jr      game_update_road_new_end
.game_update_road_new
    call    _xcs_get_random_number
.game_update_road_new_div3
    sub     $03
    jr      nc, game_update_road_new_div3
    add     a, $02
    add     a, (hl)
    jp      m, game_update_road_new_left
    cp      GAME_ROAD_LIMIT_RIGHT
    jr      c, game_update_road_new_end
    ld      a, GAME_ROAD_LIMIT_RIGHT
    jr      game_update_road_new_end
.game_update_road_new_left
    xor     a
.game_update_road_new_end
    inc     hl
    ld      (hl), a

    ; 終了
    ret

; 道を描画する
;
.game_draw_road

    ; 道の描画
    ld      bc, XCS_IO_TEXT_VRAM_0
    ld      de, $0000
.game_draw_road_loop
    push    bc

    ; 道の存在
    ld      hl, game_road_locate
    add     hl, de
    ld      a, (hl)
    cp      $ff
    jr      z, game_draw_road_next

    ; 1 行の描画
    push    hl
    ld      l, a
    ld      h, $00
    add     hl, bc
    ld      c, l
    ld      b, h
    ld      hl, game_road_route
    add     hl, de
    ld      a, (hl)
    pop     hl
    cp      $ff
    jr      z, game_draw_road_null
    sub     (hl)
    cp      $08
    jr      c, game_draw_road_calc
.game_draw_road_null
    xor     a
.game_draw_road_calc
    push    de
    add     a, a
    add     a, a
    add     a, a
    ld      e, a
;   ld      d, $00
    ld      hl, game_road_pattern
    add     hl, de
    ld      d, $08
.game_draw_road_pattern
    ld      a, (hl)
    out     (c), a
    inc     hl
    inc     bc
    dec     d
    jr      nz, game_draw_road_pattern
    pop     de

    ; 次の行へ
.game_draw_road_next
    pop     bc
    ld      hl, XCS_IO_TEXT_VRAM_SIZE_X
    add     hl, bc
    ld      c, l
    ld      b, h
    inc     e
    ld      a, e
    cp      GAME_ROAD_SIZE
    jr      c, game_draw_road_loop

    ; 終了
    ret

; 道のデータ
;
.game_road_locate
    defs    GAME_ROAD_SIZE
.game_road_route
    defs    GAME_ROAD_SIZE
.game_road_x
    defs    $01
.game_road_y
    defs    $01

; 道のパターン
.game_road_pattern
    defb    $20, $c3, $fd, $fd, $fd, $fd, $c3, $20
    defb    $20, $c3, $fd, $fd, $fd, $fd, $c3, $20
    defb    $20, $c3, $fe, $fd, $fd, $fd, $c3, $20
    defb    $20, $c3, $fd, $fe, $fd, $fd, $c3, $20
    defb    $20, $c3, $fd, $fd, $fe, $fd, $c3, $20
    defb    $20, $c3, $fd, $fd, $fd, $fe, $c3, $20
    defb    $20, $c3, $fd, $fd, $fd, $fd, $c3, $20
    defb    $20, $c3, $fd, $fd, $fd, $fd, $c3, $20

; ペンペンを初期化する
;
.game_initialize_penpen

    ; 位置の設定
    ld      a, GAME_PENPEN_START_X
    ld      (game_penpen_x), a

    ; アニメーションの設定
    ld      a, GAME_PENPEN_TILESET
    ld      (game_penpen_animation), a

    ; 消去の設定
    ld      a, $ff
    ld      (game_penpen_erase), a

    ; 終了
    ret

; ペンペンを更新する
;
.game_update_penpen

    ; 消去のクリア
    ld      a, $ff
    ld      (game_penpen_erase), a

    ; ペンペンの移動
    ld      hl, game_penpen_x
    ld      a, (_xcs_controller_push)
    bit     XCS_IO_STICK_LEFT_BIT, a
    jr      nz, game_update_penpen_move_left
    bit     XCS_IO_STICK_RIGHT_BIT, a
    jr      nz, game_update_penpen_move_right
    jr      game_update_penpen_move_end
.game_update_penpen_move_left
    ld      a, (hl)
    cp      GAME_PENPEN_LIMIT_LEFT + $01
    jr      c, game_update_penpen_move_end
    dec     (hl)
    inc     a
    ld      (game_penpen_erase), a
    jr      game_update_penpen_move_end
.game_update_penpen_move_right
    ld      a, (hl)
    cp      GAME_PENPEN_LIMIT_RIGHT
    jr      nc, game_update_penpen_move_end
    inc     (hl)
    dec     a
    ld      (game_penpen_erase), a
;   jr      game_update_penpen_move_end
.game_update_penpen_move_end

    ; 経路の設定
    ld      a, (game_penpen_x)
    ld      (game_road_route + GAME_PENPEN_Y), a

    ; アニメーションの更新
    ld      a, (game_penpen_animation)
    add     a, GAME_PENPEN_TILESET_SIZE
    cp      GAME_PENPEN_TILESET + GAME_PENPEN_TILESET * GAME_PENPEN_ANIMATION_SIZE
    jr      c, game_update_penpen_animation_end
    ld      a, GAME_PENPEN_TILESET
.game_update_penpen_animation_end
    ld      (game_penpen_animation), a

    ; 終了
    ret

; ペンペンを描画する
;
.game_draw_penpen

    ; ペンペンの描画
    ld      a, (game_penpen_x)
    dec     a
    ld      e, a
    ld      d, GAME_PENPEN_Y - $02
    ld      a, (game_penpen_animation)
    ld      b, GAME_PENPEN_TILESET_SIZE_Y
.game_draw_penpen_y
    push    de
    ld      c, GAME_PENPEN_TILESET_SIZE_X
.game_draw_penpen_x
    push    bc
    push    af
    push    de
    ld      hl, game_sprite
    call    _xcs_draw_8x8_tile
    pop     de
    inc     e
    pop     af
    inc     a
    pop     bc
    dec     c
    jr      nz, game_draw_penpen_x
    pop     de
    inc     d
    djnz    game_draw_penpen_y

    ; 移動後のペンペンの消去
    ld      a, (game_penpen_erase)
    cp      $ff
    jr      z, game_draw_penpen_erase_end
    ld      e, a
    ld      d, GAME_PENPEN_Y - $02
    push    de
    ld      hl, game_sprite
    xor     a
    call    _xcs_draw_8x8_tile
    pop     de
    inc     d
    push    de
    ld      hl, game_sprite
    xor     a
    call    _xcs_draw_8x8_tile
    pop     de
    inc     d
;   push    de
    ld      hl, game_sprite
    xor     a
    call    _xcs_draw_8x8_tile
;   pop     de
;   inc     d
.game_draw_penpen_erase_end

    ; 終了
    ret

; ペンペンのデータ
;
.game_penpen_x
    defs    $01
.game_penpen_animation
    defs    $01
.game_penpen_erase
    defs    $01

; スプライト
;
.game_sprite
    incbin  "resources/tilesets/sprite.ts"
