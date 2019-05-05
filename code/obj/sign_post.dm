/obj/sign_post
	name = "signpost"
	icon = 'icons/obj/sign_post.dmi'
	icon_state = "empty"
	flags = FPRINT
	throwforce = 10
	pressure_resistance = 3*ONE_ATMOSPHERE
	desc = "A signpost."
	anchored = 0
	density = 1
	var/words = null
	var/message_length = 0

	var/health = 50

	get_desc(dist)
		. = "<br><span style='color: blue'>It says:</span><br>[words]"

	ex_act(severity)
		switch(severity)
			if(1)
				qdel(src)
				return
			if(2)
				if (prob(50))
					qdel(src)
					return
			if(3)
				if (prob(5))
					qdel(src)
					return
			else
				return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/crowbar))
			playsound(src.loc, "sound/items/Crowbar.ogg", 50, 1)
			var/obj/item/sign_post_parts/S = new /obj/item/sign_post_parts(src.loc)
			if (src.words)
				S.words = src.words
				S.icon_state = "parts_written"
			if (src.message_length)
				S.message_length = src.message_length
			S.health = src.health
			qdel(src)

		else if (istype(W, /obj/item/screwdriver))
			playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
			src.anchored = !(src.anchored)

		else if (istype(W, /obj/item/pen))
			var/obj/item/pen/P = W
			if (!src || !user || P.in_use || get_dist(src, user) > 1)
				return
			if (src.message_length >= MAX_MESSAGE_LEN)
				boutput(user, "<span style=\"color:red\">There's not enough room left to write anything!.</span>")
				return
			P.in_use = 1
			var/t = input(user, "What do you want to write?", null, null) as null|text
			if (!t || get_dist(src, user) > 1)
				P.in_use = 0
				return
			logTheThing("station", user, null, "writes on [src] with [P] at [showCoords(src.x, src.y, src.z)]: [t]")
			t = copytext(html_encode(t), 1, (MAX_MESSAGE_LEN - src.message_length))
			if (src.words)
				src.words = "[src.words] <span style='color: [P.font_color]'>[t]</span>"
			else
				src.words = "<span style='color: [P.font_color]'>[t]</span>"
			src.message_length = src.message_length + lentext(t)+1
			P.in_use = 0
			src.icon_state = "written"
		else if (istype(W, /obj/item/grab/)) 	//grabsmash
			var/obj/item/grab/G = W
			if  (!grab_smash(G, user))
				return ..(W, user)
			else return
		else
			src.visible_message("<span style=\"color:red\"><b>[user]</b> bashes [src] with the [W]!</span>")
			playsound(src.loc, "sound/effects/zhit.ogg", 100, 1)
			src.health -= W.force
			checkhealth()
			return

		return

	verb/rotate()
		set name = "Rotate"
		set category = "Local"
		set src in oview(1)
		src.dir = turn(src.dir, 90)
		return

	proc/checkhealth()
		if(src.health <= 0)
			src.visible_message("<span style=\"color:red\"><b>[src] collapses!</b></span>")
			playsound(src.loc, "sound/effects/wbreak.wav", 100, 1)
			qdel(src)


/obj/item/sign_post_parts
	name = "signpost parts"
	icon = 'icons/obj/sign_post.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "parts_empty"
	desc = "A collection of parts that can be used to create a signpost."
	stamina_damage = 35
	stamina_cost = 35
	stamina_crit_chance = 10
	var/words = null
	var/message_length = 0
	burn_point = 400
	burn_output = 1500
	burn_possible = 1
	health = 50
	get_desc(dist)
		. = "<br><span style='color: blue'>It says:</span><br>[words]"

	attack_self(mob/user as mob)

		var/obj/sign_post/newSign = new/obj/sign_post(get_turf(user))

		if (src.words)
			newSign.words = src.words
			newSign.icon_state = "written"
		if (src.message_length)
			newSign.message_length = src.message_length
		newSign.health = src.health
		newSign.add_fingerprint(user)
		logTheThing("station", user, null, "builds a sign at [log_loc(user)].")
		user.u_equip(src)
		qdel(src)

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/pen))
			var/obj/item/pen/P = W
			if (!src || !user || P.in_use || get_dist(src, user) > 1)
				return
			if (src.message_length >= MAX_MESSAGE_LEN)
				boutput(user, "<span style=\"color:red\">There's not enough room left to write anything!.</span>")
				return
			P.in_use = 1
			var/t = input(user, "What do you want to write?", null, null) as null|text
			if (!t || get_dist(src, user) > 1)
				P.in_use = 0
				return
			logTheThing("station", user, null, "writes on [src] with [P] at [showCoords(src.x, src.y, src.z)]: [t]")
			t = copytext(html_encode(t), 1, (MAX_MESSAGE_LEN - src.message_length))
			if (src.words)
				src.words = "[src.words] <span style='color: [P.font_color]'>[t]</span>"
			else
				src.words = "<span style='color: [P.font_color]'>[t]</span>"
			src.message_length = src.message_length + lentext(t)+1
			P.in_use = 0
			src.icon_state = "parts_written"
		else if(istype(W, /obj/item/cable_coil))
			var/obj/item/cable_coil/coil = W
			coil.use(1)
			var/obj/item/clothing/suit/sandwich_board/S = new /obj/item/clothing/suit/sandwich_board(get_turf(usr))
			if (src.words)
				S.words = src.words
			if (src.message_length)
				S.message_length = src.message_length
			S.health = src.health
			user.u_equip(src)
			qdel(src)
		else
			..()
