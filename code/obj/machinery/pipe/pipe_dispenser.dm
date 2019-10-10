/*
/obj/machinery/pipedispenser
	name = "Pipe Dispenser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "autolathe"
	density = 1
	anchored = 1.0

/obj/machinery/pipedispenser/attack_hand(user as mob)
	if(..())
		return

	var/dat = {"
<A href='?src=\ref[src];make=0'>Pipe<BR>
<A href='?src=\ref[src];make=1'>Bent Pipe<BR>
<A href='?src=\ref[src];make=2'>Heat Exchange Pipe<BR>
<A href='?src=\ref[src];make=3'>Heat Exchange Bent Pipe<BR>
<A href='?src=\ref[src];make=4'>Connector<BR>
<A href='?src=\ref[src];make=5'>Manifold<BR>
<A href='?src=\ref[src];make=6'>Junction<BR>
<A href='?src=\ref[src];make=7'>Vent<BR>
<A href='?src=\ref[src];make=8'>Valve<BR>
<A href='?src=\ref[src];make=9'>Pipe-Pump<BR>"}
//<A href='?src=\ref[src];make=10'>Filter Inlet<BR>


	user << browse("<HEAD><TITLE>Pipe Dispenser</TITLE></HEAD><TT>[dat]</TT>", "window=pipedispenser")
	onclose(user, "pipedispenser")
	return

/obj/machinery/pipedispenser/Topic(href, href_list)
	if(..())
		return
	usr.machine = src
	src.add_fingerprint(usr)
	if(href_list["make"])
		var/p_type = text2num(href_list["make"])
		var/obj/item/pipe/P = new /obj/item/pipe(src.loc)
		P.pipe_type = p_type
		P.update()

	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.attack_hand(M)
	return

/obj/machinery/pipedispenser/New()
	..()
*/

/obj/machinery/disposal_pipedispenser
	name = "Disposal Pipe Dispenser"
	icon = 'icons/obj/manufacturer.dmi'
	icon_state = "fab"
	density = 1
	anchored = 1.0
	mats = 16


/obj/machinery/disposal_pipedispenser/attack_hand(user as mob)
	if(..())
		return

	var/dat = {"<b>Disposal Pipes</b><br><br>
<A href='?src=\ref[src];dmake=0'>Pipe</A><BR>
<A href='?src=\ref[src];dmake=1'>Bent Pipe</A><BR>
<A href='?src=\ref[src];dmake=2'>Junction</A><BR>
<A href='?src=\ref[src];dmake=3'>Y-Junction</A><BR>
<A href='?src=\ref[src];dmake=4'>Trunk</A><BR>
"}

	user << browse("<HEAD><TITLE>Disposal Pipe Dispenser</TITLE></HEAD><TT>[dat]</TT>", "window=pipedispenser")
	return

// 0=straight, 1=bent, 2=junction-j1, 3=junction-j2, 4=junction-y, 5=trunk


/obj/machinery/disposal_pipedispenser/Topic(href, href_list)
	if(..())
		return
	usr.machine = src
	src.add_fingerprint(usr)
	if(href_list["dmake"])
		var/p_type = text2num(href_list["dmake"])
		var/obj/disposalconstruct/C = new (src.loc)
		switch(p_type)
			if(0)
				C.ptype = 0
			if(1)
				C.ptype = 1
			if(2)
				C.ptype = 2
			if(3)
				C.ptype = 4
			if(4)
				C.ptype = 5

		C.update()

		usr << browse(null, "window=pipedispenser")
		usr.machine = null
	return

/obj/machinery/disposal_pipedispenser/mobile
	name = "Portable Disposal Pipe Dispenser"
	desc = "A tool for removing some of the tedium from pipe-laying."
	anchored = 0
	density = 1
	mats = 16
	var/laying_pipe = 0

	Move(var/turf/NewLoc,direction)
		var/turf/oldloc = loc
		..()
		if(src.laying_pipe)
			src.lay_pipe(NewLoc,oldloc,direction)


	proc/lay_pipe(var/turf/newloc,var/turf/oldloc,var/direction)
		if(!find_pipe(newloc))
			var/obj/disposalpipe/segment/S = new/obj/disposalpipe/segment(newloc)
			S.dir = direction
			S.dpdir = S.dir | turn(S.dir, 180)
			S.update()

		var/obj/disposalpipe/segment/old_pipe = find_pipe(oldloc)

		if(istype(old_pipe))
			if(old_pipe.icon_state == "pipe-s")

				if((old_pipe.dir == direction) || (turn(old_pipe.dir,180) == direction)) // no change necessary
					return

				var/list/seek_directions = list()

				if(old_pipe.dpdir & 1)
					seek_directions += 1

				if(old_pipe.dpdir & 2)
					seek_directions += 2

				if(old_pipe.dpdir & 4)
					seek_directions += 4

				if(old_pipe.dpdir & 8)
					seek_directions += 8

				for(var/direct in seek_directions)
					var/obj/disposalpipe/D = find_pipe(get_step(get_turf(old_pipe),direct))
					if(D) // already existing connection
						if(D.dpdir & get_dir(D,old_pipe)) //pipe points towards us
							seek_directions -= direct

				var/check_dir = null
				if(seek_directions.len)
					check_dir = pick(seek_directions) //idk why the fuck not, okay? get off my back. maybe we make this upgrade it to a junction, idk

				var/c_dir = null
				switch(check_dir) // hacky but i couldn't find a better way to manage this since I couldn't see a convenient pattern to the resulting bent pipe directions
					if(1)
						switch(direction)
							if(4)
								c_dir = 4
							if(8)
								c_dir = 2
					if(2)
						switch(direction)
							if(4)
								c_dir = 1
							if(8)
								c_dir = 8
					if(4)
						switch(direction)
							if(1)
								c_dir = 8
							if(2)
								c_dir = 2
					if(8)
						switch(direction)
							if(1)
								c_dir = 1
							if(2)
								c_dir = 4

				if(c_dir)
					old_pipe.icon_state = "pipe-c"
					old_pipe.base_icon_state = old_pipe.icon_state
					old_pipe.dir = c_dir
					old_pipe.dpdir = old_pipe.dir | turn(old_pipe.dir, -90)
					old_pipe.update()

		return

	proc/find_pipe(var/turf/to_find)
		. = null
		for(var/obj/disposalpipe/D in to_find)
			. = D
			break
		return

	Topic(href, href_list)
		usr.machine = src
		src.add_fingerprint(usr)
		if(href_list["dmake"])
			var/p_type = text2num(href_list["dmake"])
			if(p_type == 5)
				src.laying_pipe = !(src.laying_pipe)
				return
			else if (p_type)
				var/obj/disposalconstruct/C = new (src.loc)
				switch(p_type)
					if(0)
						C.ptype = 0
					if(1)
						C.ptype = 1
					if(2)
						C.ptype = 2
					if(3)
						C.ptype = 4
					if(4)
						C.ptype = 5

				C.update()

			usr << browse(null, "window=pipedispenser")
			usr.machine = null
		return

/obj/machinery/disposal_pipedispenser/mobile/attack_hand(user as mob)
	if(..())
		return
	var/startstop = (src.laying_pipe ? "Stop" : "Start")

	var/dat = {"<b>Disposal Pipes</b><br><br>
<A href='?src=\ref[src];dmake=0'>Pipe</A><BR>
<A href='?src=\ref[src];dmake=1'>Bent Pipe</A><BR>
<A href='?src=\ref[src];dmake=2'>Junction</A><BR>
<A href='?src=\ref[src];dmake=3'>Y-Junction</A><BR>
<A href='?src=\ref[src];dmake=4'>Trunk</A><BR><BR>
<A href='?src=\ref[src];dmake=5'>[startstop] Laying Pipe Automatically</A><BR>
"}

	user << browse("<HEAD><TITLE>Disposal Pipe Dispenser</TITLE></HEAD><TT>[dat]</TT>", "window=pipedispenser")
	return

// 0=straight, 1=bent, 2=junction-j1, 3=junction-j2, 4=junction-y, 5=trunk

