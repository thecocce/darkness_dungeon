import 'dart:async';

import 'package:bonfire/bonfire.dart';
import 'package:darkness_dungeon/enemies/imp.dart';
import 'package:darkness_dungeon/enemies/mini_boss.dart';
import 'package:darkness_dungeon/main.dart';
import 'package:darkness_dungeon/util/custom_sprite_animation_widget.dart';
import 'package:darkness_dungeon/util/enemy_sprite_sheet.dart';
import 'package:darkness_dungeon/util/functions.dart';
import 'package:darkness_dungeon/util/game_sprite_sheet.dart';
import 'package:darkness_dungeon/util/localization/strings_location.dart';
import 'package:darkness_dungeon/util/npc_sprite_sheet.dart';
import 'package:darkness_dungeon/util/player_sprite_sheet.dart';
import 'package:darkness_dungeon/util/sounds.dart';
import 'package:flutter/material.dart';

class Boss extends SimpleEnemy with ObjectCollision {
  final Vector2 initPosition;
  double attack = 40;

  bool addChild = false;
  bool firstSeePlayer = false;
  List<Enemy> childrenEnemy = [];

  Boss(this.initPosition)
      : super(
          animation: EnemySpriteSheet.bossAnimations(),
          position: initPosition,
          size: Vector2(tileSize * 1.5, tileSize * 1.7),
          speed: tileSize / 0.35,
          life: 200,
        ) {
    setupCollision(
      CollisionConfig(
        collisions: [
          CollisionArea.rectangle(
            size: Vector2(valueByTileSize(14), valueByTileSize(16)),
            align: Vector2(valueByTileSize(5), valueByTileSize(11)),
          ),
        ],
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    this.drawDefaultLifeBar(canvas);
    drawBarSummonEnemy(canvas);

    super.render(canvas);
  }

  @override
  void update(double dt) {
    if (!firstSeePlayer) {
      this.seePlayer(
        observed: (p) {
          firstSeePlayer = true;
          gameRef.camera.moveToTargetAnimated(
            this,
            zoom: 2,
            finish: () {
              _showConversation();
            },
          );
        },
        radiusVision: tileSize * 5,
      );
    }

    if (life < 150 && childrenEnemy.length == 0) {
      addChildInMap(dt);
    }

    if (life < 100 && childrenEnemy.length == 1) {
      addChildInMap(dt);
    }

    if (life < 50 && childrenEnemy.length == 2) {
      addChildInMap(dt);
    }

    this.seeAndMoveToPlayer(
      closePlayer: (player) {
        execAttack();
      },
      radiusVision: tileSize * 3,
    );

    super.update(dt);
  }

  @override
  void die() {
    gameRef.add(
      AnimatedObjectOnce(
        animation: GameSpriteSheet.explosion(),
        position: this.position,
        size: Vector2(32, 32),
      ),
    );
    childrenEnemy.forEach((e) {
      if (!e.isDead) e.die();
    });
    removeFromParent();
    super.die();
  }

  void addChildInMap(double dt) {
    if (checkInterval('addChild', 5000, dt)) {
      Vector2 positionExplosion;

      switch (this.directionThePlayerIsIn()) {
        case Direction.left:
          positionExplosion = this.position.translate(width * -2, 0);
          break;
        case Direction.right:
          positionExplosion = this.position.translate(width * 2, 0);
          break;
        case Direction.up:
          positionExplosion = this.position.translate(0, height * -2);
          break;
        case Direction.down:
          positionExplosion = this.position.translate(0, height * 2);
          break;
        case Direction.upLeft:
          // TODO: Handle this case.
          break;
        case Direction.upRight:
          // TODO: Handle this case.
          break;
        case Direction.downLeft:
          // TODO: Handle this case.
          break;
        case Direction.downRight:
          // TODO: Handle this case.
          break;
      }

      Enemy e = childrenEnemy.length == 2
          ? MiniBoss(
              Vector2(
                positionExplosion.x,
                positionExplosion.y,
              ),
            )
          : Imp(
              Vector2(
                positionExplosion.x,
                positionExplosion.y,
              ),
            );

      gameRef.add(
        AnimatedObjectOnce(
          animation: GameSpriteSheet.smokeExplosion(),
          position: positionExplosion,
          size: Vector2(32, 32),
        ),
      );

      childrenEnemy.add(e);
      gameRef.add(e);
    }
  }

  void execAttack() {
    this.simpleAttackMelee(
      size: Vector2.all(tileSize * 0.62),
      damage: attack,
      interval: 1500,
      animationDown: EnemySpriteSheet.enemyAttackEffectBottom(),
      animationLeft: EnemySpriteSheet.enemyAttackEffectLeft(),
      animationRight: EnemySpriteSheet.enemyAttackEffectRight(),
      animationUp: EnemySpriteSheet.enemyAttackEffectTop(),
      execute: () {
        Sounds.attackEnemyMelee();
      },
    );
  }

  @override
  void receiveDamage(double damage, dynamic id) {
    this.showDamage(
      damage,
      config: TextStyle(
        fontSize: valueByTileSize(5),
        color: Colors.white,
        fontFamily: 'Normal',
      ),
    );
    super.receiveDamage(damage, id);
  }

  void drawBarSummonEnemy(Canvas canvas) {
    if (position == null) return;
    double yPosition = position.y;
    double widthBar = (width - 10) / 3;
    if (childrenEnemy.length < 1)
      canvas.drawLine(
          Offset(position.x, yPosition),
          Offset(position.x + widthBar, yPosition),
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 1
            ..style = PaintingStyle.fill);

    double lastX = position.x + widthBar + 5;
    if (childrenEnemy.length < 2)
      canvas.drawLine(
          Offset(lastX, yPosition),
          Offset(lastX + widthBar, yPosition),
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 1
            ..style = PaintingStyle.fill);

    lastX = lastX + widthBar + 5;
    if (childrenEnemy.length < 3)
      canvas.drawLine(
          Offset(lastX, yPosition),
          Offset(lastX + widthBar, yPosition),
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 1
            ..style = PaintingStyle.fill);
  }

  void _showConversation() {
    Sounds.interaction();
    TalkDialog.show(gameRef.context, [
      Say(
        text: [TextSpan(text: getString('talk_kid_1'))],
        person: CustomSpriteAnimationWidget(
          animation: NpcSpriteSheet.kidIdleLeft(),
        ),
        personSayDirection: PersonSayDirection.RIGHT,
      ),
      Say(
        text: [TextSpan(text: getString('talk_boss_1'))],
        person: CustomSpriteAnimationWidget(
          animation: EnemySpriteSheet.bossIdleRight(),
        ),
        personSayDirection: PersonSayDirection.LEFT,
      ),
      Say(
        text: [TextSpan(text: getString('talk_player_3'))],
        person: CustomSpriteAnimationWidget(
          animation: PlayerSpriteSheet.idleRight(),
        ),
        personSayDirection: PersonSayDirection.LEFT,
      ),
      Say(
        text: [TextSpan(text: getString('talk_boss_2'))],
        person: CustomSpriteAnimationWidget(
          animation: EnemySpriteSheet.bossIdleRight(),
        ),
        personSayDirection: PersonSayDirection.RIGHT,
      ),
    ], onFinish: () {
      Sounds.interaction();
      addInitChild();
      Future.delayed(Duration(milliseconds: 500), () {
        gameRef.camera.moveToPlayerAnimated();
        Sounds.playBackgroundBoosSound();
      });
    }, onChangeTalk: (index) {
      Sounds.interaction();
    });
  }

  void addInitChild() {
    addImp(position.x - tileSize, position.x - tileSize);
    addImp(position.x - tileSize, position.x); //position.bottom + tileSize);
  }

  void addImp(double x, double y) {
    gameRef.add(
      AnimatedObjectOnce(
        animation: GameSpriteSheet.smokeExplosion(),
        position: Vector2(x, y),
        size: Vector2(32, 32),
      ),
    );
    gameRef.add(Imp(
      Vector2(x, y),
    ));
  }
}
