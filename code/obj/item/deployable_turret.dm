/obj/item/turret_deployer
	name = "Syndicate Turret"
	desc = "A turret that fires at non-agents in a 90 degree arc. Weld to attach to the floor."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "coilgun"
	force = 3.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 5
	w_class = 4

	attackby(obj/item/W, mob/user)

		if(istype(W, /obj/item/weldingtool) && W:welding)

			var/turf/T = user.loc

			if (!istype(src.loc, /turf))
				boutput(user, "You can't weld the turret down there!")
				return

			if (W:get_fuel() < 1)
				boutput(user, "<span style=\"color:blue\">You need more welding fuel to complete this task.</span>")
				return
			W:use_fuel(1)

			boutput(user, "You start to weld the turret to the floor.")
			playsound(src.loc, "sound/items/Welder2.ogg", 50, 1)
			sleep(10)

			if ((user.loc == T && user.equipped() == W))
				W:eyecheck(user)
				boutput(user, "You weld the turret to the floor.")
				var/obj/deployable_turret/turret = new /obj/deployable_turret(src.loc)
				turret.dir = get_dir(T,src.loc)
				qdel(src)
			else if((istype(user, /mob/living/silicon/robot) && (user.loc == T)))
				boutput(user, "You weld the turret to the floor.")
				var/obj/deployable_turret/turret = new /obj/deployable_turret(src.loc)
				turret.dir = get_dir(T,src.loc)
				qdel(src)
			return


/obj/deployable_turret

	name = "turret"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "coilgun"
	anchored = 1
	density = 1
	var/health = 100
	var/list/mob/target_list = list()
	//var/list/turf/valid_turfs = list()
	var/mob/target = null
	var/cycle_time = 5 // loop every half second
	var/wait_time = 20 //wait if it can't find a target
	var/range = 7
	var/end_angle = 45

	New()
		..()
		spawn(src.wait_time)
			src.process()

	proc/process()

		while(src.health > 0)
			boutput(world, "processing!")
			if(!src.target)
				boutput(world, "no target, seeking!")
				if(!src.seek_target())
					boutput(world, "can't find target, sleeping!")
					sleep(src.wait_time)
					continue
			boutput(world, "Target found: [src.target.name]")
			if(!src.target_valid(src.target))
				src.target = null
				boutput(world, "target no longer valid, sleeping!")
				sleep(src.cycle_time)
				continue
			else
				boutput(world, "target valid, shooting!")
				shoot(src.target)
				sleep(src.cycle_time)

		boutput(world, "oh no! dying!")
		src.die()

	proc/seek_target()

		src.target_list = list()

		for (var/mob/C in view(src.range,src))
			//boutput(world, "Checking if [C.name] is a valid target!")
			if (!src)
				break
			else if (src.target_valid(C))
				//boutput(world, "Target valid! Adding to list!")
				src.target_list += C
			else
				continue
		if (src.target_list.len>0)
			src.target = pick(src.target_list)
			boutput(world, "Target chosen: [src.target]!")
		return src.target

	proc/target_valid(var/mob/C)
		if(get_dist(C.loc,src.loc > src.range))
			return 0
		if (!C)
			return 0
		if (C.health < 0)
			return 0

		switch(src.dir)
			if(NORTH)
				src.end_angle = 45
			if(NORTHWEST)
				src.end_angle = 90
			if(WEST)
				src.end_angle = 135
			if(SOUTHWEST)
				src.end_angle = 270
			if(SOUTH)
				src.end_angle = 225
			if(SOUTHEAST)
				src.end_angle = 270
			if(EAST)
				src.end_angle = 315
			if(NORTHEAST)
				src.end_angle = 360
			else
				src.die() // how did you get here? just go away!


		var/angle = get_angle(src,C)

		angle = angle < 0 ? angle+360 : angle

		//boutput(world, "angle between [src.name] and [C.name] is [angle].")

		if(src.dir == NORTH)
			if (angle > 315 || angle < 45)
				//boutput(world, "[C.name] marked as valid target.")
				return 1
		else
			if((angle <= src.end_angle) && (angle >= (src.end_angle - 90)))
				//boutput(world, "[C.name] marked as valid target.")
				return 1

		return 0

	proc/shoot(var/mob/target)
		boutput(world, "BANG! [src.name] shoots at [target.name]!")

	bullet_act(var/obj/projectile/P)
		src.health = src.health - P.power

	proc/die()
		qdel(src)
