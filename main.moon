-- Copyright (c) 2012 Ryusei Yamaguchi
--
-- This software is provided 'as-is', without any express or implied
-- warranty.  In no event will the authors be held liable for any damages
-- arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
--
-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software. If you use this software
--    in a product, an acknowledgment in the product documentation would be
--    appreciated but is not required.
-- 2. Altered source versions must be plainly marked as such, and must not be
--    misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.

require 'sui'
require 'kanaui'

import rectangle from love.graphics

local font
local ui
local reload
local kanacard, card

white = {255, 255, 255, 170}
black = {0, 0, 0, 255}
vermilion = {0xF2, 0x66, 0x49, 255}
gray = {220, 220, 220, 200}

background_color = {0x40, 0x6a, 0xbf, 255}

front_color = {255, 255, 204, 255}
back_color = {204, 255, 255, 255}

angle = 0

hiragana_table = {
	'あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ',
	'さ', 'し', 'す', 'せ', 'そ', 'た', 'ち', 'つ', 'て', 'と',
	'な', 'に', 'ぬ', 'ね', 'の', 'は', 'ひ', 'ふ', 'へ', 'ほ',
	'ま', 'み', 'む', 'め', 'も', 'や', 'ゆ', 'よ',
	'ら', 'り', 'る', 'れ', 'ろ', 'わ', 'を', 'ん',
}

to_katakana = (hiragana) ->
	local ls, rs, unicode
	ls = (l, r) -> l * (2^r)
	rs = (l, r) -> math.floor(l / (2^r))
	s1, s2, s3 = string.byte hiragana, 1, 3
	s1 %= 0x10
	s2 %= 0x40
	s3 %= 0x40
	unicode = ls(s1, 12) + ls(s2, 6) + s3
	unicode += 0x60
	return string.char 0xe0 + rs(unicode, 12), 0x80 + rs(unicode, 6)%0x40, 0x80 + unicode%0x40

shuffle = (t) ->
	t2 = {}
	l = #t
	for i = 1, l
		t2[i] = table.remove(t, math.random(#t))
	return t2

kanas = {}
cards = {}
flips = {}
matchs = {}
colors = {}
match_num = 0
count = 0

newgame = ->
	local c
	ht = shuffle({k, v for k, v in pairs hiragana_table})
	c = {}
	for i = 1, 6
		local hiragana
		hiragana = ht[i]
		c[i] = hiragana
		c[i + 6] = to_katakana(hiragana)
	c = shuffle(c)
	for k, v in ipairs c
		kanas[k] = v
		colors[k] = black
		matchs[k] = false
		flips[k] = true
		cards[k] = card k, kanacard k, v
	match_num = 0
	count = 0
	flag_gameover = false

kanacard = (i, c) ->
	sui.bc front_color, sui.fc (-> colors[i]), sui.margin 20, 0, sui.font (-> font[140]),
		sui.label 140, 180, (-> tostring(sui.bang(c)))

opened = {}

flag_gameover = false
gameover = -> flag_gameover = true

cardflip = (i) ->
	if not flips[i]
		table.insert(opened, i)
	else
		for j = #opened, 1, -1
			if i == opened[j]
				table.remove(opened, j)
				break
	if #opened == match_num + 2
		k1, k2 = kanas[opened[#opened - 1]], kanas[opened[#opened]]
		if k1 == to_katakana(k2) or k2 == to_katakana(k1)
			matchs[opened[#opened - 1]] = true
			matchs[opened[#opened]] = true
			match_num += 2
			colors[opened[#opened - 1]] = vermilion
			colors[opened[#opened]] = vermilion
	if match_num == 12 then gameover()

card = (i, front) ->
	local flip
	flips[i] = true
	clicked = (x, y, button) ->
		if button == 'l' and not matchs[i]
			if not flips[i] or (#opened - match_num) < 2
				if flips[i]
					count += 1
				flips[i] = not flips[i]
				cardflip(i)
	sui.margin 10, 10, sui.clicked clicked, kanaui.flipboard (-> flips[i]), 200, {
		front
		sui.bc back_color, sui.fc black, sui.font (-> font[32]), sui.label 180, 180, ''
	}

concentration = (card) ->
	sui.grid 200, 200, 800 / 200, cards

box = (width, height, widget) ->
	local size
	size = widget.size
	a = ->
		w, h = size()
		(sui.bang(width) - w) / 2
	b = ->
		w, h = size()
		(sui.bang(height) - h) / 2
	sui.margin a, b, widget

button = ->
	box 192, 40, sui.clicked (-> reload()),
		sui.bc gray, box 160, 40,
			sui.font (-> font[16]), sui.label 136, 20, 'もういちど あそぶ'

ui = sui.font (-> font[32]), sui.layer {
	concentration(card)
	sui.option (-> flag_gameover), {
		[true]: box 800, 600,
			sui.bc white, sui.fc black, box 200, 200, sui.vbox 10, {
				sui.font (-> font[64]), sui.label 192, 70, 'おわり'
				box 192, 20,
					sui.font (-> font[16]), sui.label 100, 20, 'GAME OVER'
				box 192, 20, sui.font (-> font[16]), sui.label 120, 20, (-> "#{count} かい ひらいた")
				button()
			}
	}
}

love.load = (arg) ->
	font =
		[16]: love.graphics.newFont('mplus-subset.ttf', 16)
		[64]: love.graphics.newFont('mplus-subset.ttf', 64)
		[140]: love.graphics.newFont('mplus-subset.ttf', 140)
	love.graphics.setBackgroundColor background_color
	love.graphics.setFont font[16]
	newgame()
	return

love.update = (dt) ->
	angle += dt * 2
	ui.update(dt)
	return

love.draw = ->
	ui.draw(0, 0)
	return

love.mousepressed = (x, y, button) ->
	ui.mousepressed(0, 0, x, y, button)
	return

love.mousereleased = (x, y, button) ->
	ui.mousereleased(0, 0, x, y, button)
	return

reload = ->
	love.filesystem.load('sui.lua')()
	love.filesystem.load('kanaui.lua')()
	love.filesystem.load('main.lua')()
	love.load()

love.keypressed = (key, unicode) ->
	switch key
		when 'f5'
			reload()
	return
