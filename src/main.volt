// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module main;

static import examples.gl;
static import voxel.game;
static import power.game;


fn main(args: string[]) int
{
	//g := new examples.gl.Game(args);
	g := new power.game.Game(args);
	//g := new voxel.game.Game(args);

	return g.c.loop();
}
