/obj/item/clothing/suit/hoodie/cloaker
	name = "hoodie"
	desc = "Nice and comfy on those cold space evenings."
	icon_state = "hoodie"
	item_state = "hoodie"
	cold_resistance = 10
	hood = 0
	var/battery = 5 // processing ticks of charge
	var/battery_max = 5

	New()
		..()
		if (!(src in processing_items))
			processing_items.Add(src)


	disposing()
		processing_items.Remove(src)
		..()

	process()
		if(hood)
			if(!battery)
				src.flip_hoodie()
			battery--
			battery = max(battery,0)

		else
			if(battery < battery_max)
				battery++
		boutput(world,"[src]'s battery is [battery]")

	attack_self(mob/user as mob)
		src.flip_hoodie(user)

	proc/flip_hoodie(mob/user as mob)
		src.hood = !(src.hood)
		if(user)
			user.show_text("You flip [src]'s hood [src.hood ? "up" : "down"].")
		if (src.hood)
			src.over_hair = 1
			src.icon_state = "hoodie-up"
			src.item_state = "hoodie-up"

		else
			src.over_hair = 0
			src.icon_state = "hoodie"
			src.item_state = "hoodie"

		var/mob/M = src.loc
		if(istype(M))
			M.update_inhands()
			M.update_clothing()

/obj/item/clothing/suit/hoodie/cloaker/abilities = list(/obj/ability_button/flip_cloaker_hoodie)

/obj/ability_button/flip_cloaker_hoodie
	name = "Toggle Active Camo"
	icon_state = "weldup"

	execute_ability()
		var/obj/item/clothing/suit/hoodie/cloaker/C = the_item
		C.flip_hoodie(the_mob)