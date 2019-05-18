/obj/item/turret_deployer
	name = "A.S.S."
	desc = "An Automatic Syndicate Sentry. A turret that fires at non-Syndicate threats in a 30 degree arc. Weld it to the floor to securie it, screwdriver to turn it on, and wrench it to set the angle. Welding while active will repair the turret."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "orange_target_prism"
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
			sleep(20)

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

	name = "A.S.S."
	desc = "An Automatic Syndicate Sentry."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "orange_target_prism"
	anchored = 1
	density = 1
	var/health = 100
	var/max_health = 100
	var/list/mob/living/target_list = list()
	var/mob/living/target = null
	var/cycle_time = 15 // loop minimum wait time
	var/wait_time = 30 //wait if it can't find a target
	var/range = 7
	var/internal_angle = 0
	var/external_angle = 180
	var/projectile_type = /datum/projectile/bullet/staple
	var/datum/projectile/current_projectile = new/datum/projectile/bullet/staple
	var/burst_size = 10 // number of shots to fire
	var/fire_rate = 10 // rate of fire in shots per second
	var/angle_arc_size = 30
	var/active = 0 // are we gonna shoot some peeps?

	New()
		..()

		spawn(src.wait_time)
			src.set_initial_angle()

	proc/process()
		while(src.active)
			if(!src.target)
				if(!src.seek_target())
					sleep(src.wait_time)
					continue
			if(!src.target_valid(src.target))
				src.target = null
				sleep(src.cycle_time)
				continue
			else
				for (var/i = 0, i<burst_size, i++)
					shoot(src.target.loc,src.loc,src)
					sleep(10/fire_rate)
				sleep(src.cycle_time)


	proc/seek_target()

		src.target_list = list()

		for (var/mob/living/C in view(src.range,src))
			if(!src)
				break

			if (src.target_valid(C))
				src.target_list += C

			else
				continue

		if (src.target_list.len>0)
			src.target = pick(src.target_list)

		return src.target

	proc/target_valid(var/mob/living/C)

		if(get_dist(C.loc,src.loc) > src.range)
			return 0
		if (!C)
			return 0
		if (C.health < 0)
			return 0
		if (C.stat == 2)
			return 0
		if (istype(C,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = C
			if (istype(H.wear_id,/obj/item/card/id/syndicate))
				return 0

		var/angle = get_angle(src,C)

		angle = angle < 0 ? angle+360 : angle

		angle = angle - src.external_angle

		if (angle > 180)
			angle = abs(360-angle)
		else if (angle < -180)
			angle = abs(360+angle)
		else
			angle = abs(angle)

		if (angle <= (angle_arc_size/2))
			return 1
		return 0

	proc/shoot(var/turf/target, var/start, var/user, var/bullet = 0)
		if(target == start)
			return

		var/obj/projectile/A = unpool(/obj/projectile)
		if(!A)	return
		A.set_loc(src.loc)
		if (!current_projectile)
			current_projectile = new projectile_type()
		A.proj_data = new current_projectile.type
		A.proj_data.master = A
		A.set_icon()
		A.power = A.proj_data.power
		if(src.current_projectile.shot_sound)
			playsound(src, src.current_projectile.shot_sound, 60)

		if (!istype(target, /turf))
			A.die()
			return
		A.target = target

		A.yo = target:y - start:y
		A.xo = target:x - start:x

		A.shooter = src

		spawn( 0 )
			A.process()
		return


	bullet_act(var/obj/projectile/P)
		src.health = src.health - P.power
		src.check_health()

	proc/check_health()
		if(src.health <= 0)
			src.active = 0
			src.die()
		//TODO add damage sprites and examine changes

	proc/die()
		qdel(src)
		//TODO make it spawn scrap or something
		//can't just deactivate it because welding it would let you ressurect it

	attackby(obj/item/W, mob/user)

		if (istype(W, /obj/item/weldingtool) && W:welding && !(src.active))

			var/turf/T = user.loc

			if (W:get_fuel() < 1)
				boutput(user, "<span style=\"color:blue\">You need more welding fuel to complete this task.</span>")
				return
			W:use_fuel(1)

			boutput(user, "You start to unweld the turret from the floor.")
			playsound(src.loc, "sound/items/Welder2.ogg", 50, 1)
			sleep(30)

			if ((user.loc == T && user.equipped() == W))
				W:eyecheck(user)
				boutput(user, "You unweld the turret from the floor.")
				src.active = 0
				new /obj/item/turret_deployer(src.loc)
				qdel(src)
			else if((istype(user, /mob/living/silicon/robot) && (user.loc == T)))
				boutput(user, "You unweld the turret to the floor.")
				src.active = 0
				new /obj/item/turret_deployer(src.loc)
				qdel(src)
			return

		if (istype(W, /obj/item/weldingtool) && W:welding && (src.active))

			var/turf/T = user.loc

			if (src.health >= max_health)
				boutput(user, "<span style=\"color:blue\">The turret is already fully repaired!.</span>")
				return

			if (W:get_fuel() < 1)
				boutput(user, "<span style=\"color:blue\">You need more welding fuel to complete this task.</span>")
				return
			W:use_fuel(1)

			boutput(user, "You start to repair the turret.")
			playsound(src.loc, "sound/items/Welder2.ogg", 50, 1)
			sleep(00)

			if ((user.loc == T && user.equipped() == W))
				W:eyecheck(user)
				boutput(user, "You repair some of the damage on the turret.")
				src.health = min(src.max_health, (src.health + 20))
				src.check_health()
			return


		else if (istype(W, /obj/item/wrench))
			var/angle = input(usr, "Degrees clockwise from North:", "What would you like to set the angle to?", 0) as num
			if(angle == null)
				return
			playsound(src.loc, "sound/items/Ratchet.ogg", 50, 1)
			src.set_angle(angle)

		else if (istype(W, /obj/item/screwdriver))
			if(src.active)
				playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You power off the turret.</span>")
				src.active = 0
			else
				playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You power on the turret.</span>")
				src.active = 1
				spawn(src.wait_time)
					src.process()

		else
			src.health = src.health - W.force
			src.check_health()

	proc/set_initial_angle()

		switch(src.dir)
			if(NORTH)
				src.external_angle = (0)
			if(NORTHEAST)
				src.external_angle = (45)
			if(EAST)
				src.external_angle = (90)
			if(SOUTHEAST)
				src.external_angle = (135)
			if(SOUTH)
				src.external_angle = (180)
			if(SOUTHWEST)
				src.external_angle = (225)
			if(WEST)
				src.external_angle = (270)
			if(NORTHEAST)
				src.external_angle = (315)
			else
				src.external_angle = (180) // how did you get here?

		boutput(world, "Initializing external angle as [src.external_angle]")
		boutput(world, "Initializing internal angle as [src.internal_angle]")

	proc/set_angle(var/angle)

		boutput(world,"Input Angle is: [angle]")

		while(angle < 0)
			angle += 360

		while(angle > 360)
			angle -= 360

		boutput(world, "Normalized Angle is: [angle]")

		var/angle_diff = angle - src.external_angle

		var/new_internal_angle  = src.internal_angle + angle_diff

		boutput(world, "Internal Angle is: [src.internal_angle]")
		boutput(world, "New Internal Angle is: [new_internal_angle]")

		while(new_internal_angle < 0)
			new_internal_angle += 360

		while(new_internal_angle > 360)
			new_internal_angle -= 360

		boutput(world, "Normalized New Internal Angle is: [new_internal_angle]")

		src.animate_turret_turn(src.internal_angle,new_internal_angle)

		src.internal_angle = new_internal_angle
		src.external_angle = angle
		//src.dir = angle2dir(src.current_angle)

	proc/animate_turret_turn(var/curr_ang,var/new_ang)

		boutput(world,"Starting angle is [curr_ang], new angle is [new_ang].")

		var/ang = (new_ang - curr_ang)

		boutput(world,"Turning [ang] degrees clockwise.")

		//var/matrix/M = matrix()
		//M = M.Turn(ang)

		var/matrix/transform_original = src.transform
		animate(src, transform = matrix(transform_original, ang/3, MATRIX_ROTATE | MATRIX_MODIFY), time = 10/3, loop = 0) //blatant code theft from throw_at
		animate(transform = matrix(transform_original, ang/3, MATRIX_ROTATE | MATRIX_MODIFY), time = 10/3, loop = 0)
		animate(transform = matrix(transform_original, ang/3, MATRIX_ROTATE | MATRIX_MODIFY), time = 10/3, loop = 0)

		//animate(src, transform = M, time = 10, loop = 0)