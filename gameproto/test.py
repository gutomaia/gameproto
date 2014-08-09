# USED RICHARD JONES EXAMPLE AS A START POINT

import os
import sys
import pygame

if hasattr(sys, '_MEIPASS'):
    HOME = sys._MEIPASS
    #HOME = os.path.dirname(sys.executable)
else: 
    HOME = os.path.dirname(os.path.abspath(__file__))

UP = pygame.USEREVENT
DOWN = pygame.USEREVENT+1
LEFT = pygame.USEREVENT+2
RIGHT = pygame.USEREVENT+3

FIRE = pygame.USEREVENT+4
JUMP = pygame.USEREVENT+5

class Player(pygame.sprite.Sprite):
    def __init__(self, *groups):
        super(Player, self).__init__(*groups)
        self.image = pygame.image.load(os.path.join(HOME,'player.png'))
        self.rect = pygame.rect.Rect((320, 240), self.image.get_size())
        self.do_up = False
        self.do_down = False
        self.do_left = False
        self.do_right = False
        self.do_jump = False

    def jump(self):
        self.do_jump = True

    def up(self):
        self.do_up = True

    def down(self):
        self.do_down = True

    def left(self):
        self.do_left = True

    def right(self):
        self.do_right = True

    def update(self, dt, game):
        last = self.rect.copy()

        if self.do_jump:
            print "jumpping"

        if self.do_up:
            self.rect.y -= 300 * dt
        if self.do_down:
            self.rect.y += 300 * dt
        if self.do_left:
            self.rect.x -= 300 * dt
        if self.do_right:
            self.rect.x += 300 * dt

        self.do_up = False
        self.do_down = False
        self.do_left = False
        self.do_right = False

        for cell in pygame.sprite.spritecollide(self, game.walls, False):
            self.rect = last

class Game(object):
    def main(self, screen):
        clock = pygame.time.Clock()
        pygame.joystick.init()
        if pygame.joystick.get_count() > 0:
            self.joystick = pygame.joystick.Joystick(0)
            self.joystick.init()

        background = pygame.image.load(os.path.join(HOME, 'background.png'))
        sprites = pygame.sprite.Group()
        self.player = Player(sprites)

        self.walls = pygame.sprite.Group()
        block = pygame.image.load(os.path.join(HOME, 'block.png'))
        for x in range(0, 640, 32):
            for y in range(0, 480, 32):
                if x in (0, 640-32) or y in (0, 480-32):
                    wall = pygame.sprite.Sprite(self.walls)
                    wall.image = block
                    wall.rect = pygame.rect.Rect((x, y), block.get_size())
        sprites.add(self.walls)

        pygame.event.set_blocked(pygame.JOYAXISMOTION)
        while 1:
            dt = clock.tick(30)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return
                if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                    return
                if event.type == pygame.JOYBUTTONDOWN:
                    self.player.jump()

            self.deal_keyboard()
            #self.deal_joystick()

            sprites.update(dt / 1000., self)
            screen.blit(background, (0, 0))
            sprites.draw(screen)
            pygame.display.flip()

    def deal_keyboard(self):
        key = pygame.key.get_pressed()
        if key[pygame.K_UP]:
            self.player.up()
        if key[pygame.K_DOWN]:
            self.player.down()
        if key[pygame.K_LEFT]:
            self.player.left()
        if key[pygame.K_RIGHT]:
            self.player.right()

    def deal_joystick(self):
        if self.joystick:
            x = self.joystick.get_axis(0)
            y = self.joystick.get_axis(1)
            if x > 0.5:
                self.player.right()
            elif x < -0.5:
                self.player.left()
            if y > 0.5:
                self.player.down()
            elif y < -0.5:
                self.player.up()

if __name__ == '__main__':
    pygame.init()
    size = [640, 480]
    screen = pygame.display.set_mode(size)
    pygame.display.set_caption("My Super Game")
    Game().main(screen)

