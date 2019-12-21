/obj/machinery/ore_cloud_storage_container
	name = "Ore Cloud Storage Container"
	desc = "This thing stores ore in \"the cloud\" for the station to use. Best not to think about it too hard."
	icon = 'icons/obj/mining.dmi'
	icon_state = "ore_storage_unit"
	density = 1
	var/base_material_class = /obj/item/raw_material/

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)

		if (!O || !user)
			return

		if(!istype(user,/mob/living/))
			boutput(user, "<span style=\"color:red\">Only living mobs are able to use the manufacturer's quick-load feature.</span>")
			return

		if (!istype(O,/obj/))
			boutput(user, "<span style=\"color:red\">You can't quick-load that.</span>")
			return

		if(get_dist(O,user) > 1)
			boutput(user, "<span style=\"color:red\">You are too far away!</span>")
			return

		else if (istype(O, /obj/storage/crate/) && src.accept_loading(user,1))
			if (O:welded || O:locked)
				boutput(user, "<span style=\"color:red\">You cannot load from a crate that cannot open!</span>")
				return

			user.visible_message("<span style=\"color:blue\">[user] uses [src]'s automatic loader on [O]!</span>", "<span style=\"color:blue\">You use [src]'s automatic loader on [O].</span>")
			var/amtload = 0
			for (var/obj/item/M in O.contents)
				if (!istype(M,src.base_material_class))
					continue
				src.load_item(M)
				amtload++
			if (amtload) boutput(user, "<span style=\"color:blue\">[amtload] materials loaded from [O]!</span>")
			else boutput(user, "<span style=\"color:red\">No material loaded!</span>")

		else if (istype(O, /obj/item/) && src.accept_loading(user,1))
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing materials into [src]!</span>")
			var/staystill = user.loc
			for(var/obj/item/M in view(1,user))
				if (!O)
					continue
				if (!istype(M,O.type))
					continue
				if (!istype(M,src.base_material_class))
					continue
				if (O.loc == user)
					continue
				if (O in user.contents)
					continue
				src.load_item(M)
				sleep(0.5)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing materials into [src]!</span>")

		else ..()

		src.updateUsrDialog()

	proc/load_item(var/obj/item/O,var/mob/living/user)
		if (!O)
			return
		O.set_loc(src)
		if (user && O)
			user.u_equip(O)
			O.dropped()

	proc/accept_loading(var/mob/user,var/allow_silicon = 0)
		if (!user)
			return 0
		if (src.stat & BROKEN || src.stat & NOPOWER)
			return 0
		if (!istype(user, /mob/living/))
			return 0
		if (istype(user, /mob/living/silicon) && !allow_silicon)
			return 0
		var/mob/living/L = user
		if (L.stat || L.transforming)
			return 0
		return 1

	/*
	proc/add_ore(var/obj/item/raw_material/R)
		if(!istype(R))
			return
		var/material_path = R.type
		if(material_path in ores)
			ores
	*/
	proc/get_ores()
		var/list/ores = list()
		for(var/obj/item/raw_material/R in src.contents)
			if(!(R.material_name in ores))
				ores += R.material_name
				ores[R.material_name] = 1

			else
				ores[R.material_name]++

		for(var/x in ores)
			boutput(world,"[x] : [ores[x]]")
		return(ores)

	attack_hand(var/mob/user as mob)
		..()
		var/list/ores = src.get_ores()