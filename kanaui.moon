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

export kanaui

import graphics from love
import bang from sui
import min, max, cos, pi from math

kanaui = {}

kanaui.flipable = (angle, widgets) ->
	import push, pop, translate, scale from graphics
	head_widget, tail_widget = unpack(widgets)
	w1, h1 = head_widget.size()
	w2, h2 = tail_widget.size()
	w, h = max(w1, w2), max(h1, h2)
	head_draw = head_widget.draw
	tail_draw = tail_widget.draw
	func = (name, widgets) -> (...) ->
		o = cos(bang(angle))
		if o >= 0
			f = head_widget[name]
		else
			f = tail_widget[name]
		if type(f) == 'function' then f ...
	obj = sui.container func, widgets
	obj.size = -> return w, h
	obj.draw = (x, y) ->
		push()
		o = cos(bang(angle))
		if o >= 0
			translate x + w / 2 * (1 - o), y
			scale o, 1
			head_draw(0, 0)
		else
			translate x + w / 2 * (1 + o), y
			scale -o, 1
			tail_draw(0, 0)
		pop()
	func = (name) ->
		f_h, f_t = head_widget[name], tail_widget[name]
		(wx, wy, mx, my, ...) ->
			local f
			o = cos(bang(angle))
			x = mx - wx
			if o >= 0
				f = f_h
				x = (x - w / 2 * (1 - o)) / o
			else
				f = f_t
				x = (x - w / 2 * (1 + o)) / (-o)
			if type(f) == 'function'
				f 0, 0, x, (my - wy), ...
	obj.mousepressed = func 'mousepressed'
	obj.mousereleased = func 'mousereleased'
	return obj

tf_linear = (t) ->
	v = 1000 / t
	x = 0
	(dt) ->
		x += v * dt
		return x

constrain = (m, M, f) -> (...) -> max m, min(M, f ...)

value_map = (x1, x2, f) ->
	dx = x2 - x1
	(...) ->
		x1 + f(...) * dx

kanaui.flipboard = (flip, time, widgets) ->
	local side, angle, angleupdate, update
	side = bang(flip)
	angle = if side then pi else 0
	angleupdate = (dt) -> angle
	update = (dt) ->
		s = bang(flip)
		if side ~= s
			angleupdate = if s then
				value_map angle, pi, constrain 0, 1, tf_linear bang(time)
			else
				value_map angle, 0, constrain 0, 1, tf_linear bang(time)
			side = s
		angle = angleupdate dt
	sui.update update, kanaui.flipable (-> angle), widgets
