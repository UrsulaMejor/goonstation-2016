/obj/item/stick
	name = "popsicle stick"
	desc = "You made a house out of these once in kindergarten."
	icon = 'icons/obj/foodNdrink/popsicles.dmi'
	icon_state = "stick"
	throwforce = 1
	w_class = 1.0
	throw_speed = 4
	throw_range = 5
	w_class = 1.0
	stamina_damage = 1
	stamina_cost = 1



/obj/item/reagent_containers/food/snacks/popsicle
	name = "popsicle"
	desc = "A popsicle. It's in a wrapper right now."
	icon = 'icons/obj/foodNdrink/popsicles.dmi'
	icon_state = "popsiclewrapper"
	amount = 4
	heal_amt = 4
	food_color = null
	initial_volume = 40
	var/opened = 0
	var/flavor = ""

	New()
		..()
		var/datum/reagents/R = reagents
		if(prob(1))
			src.flavor = "orangecreamsicle"
			R.add_reagent("juice_orange", 5)
			R.add_reagent("omnizine", 5)
			R.add_reagent("oculine", 5)
			R.add_reagent("vanilla", 5)
			R.add_reagent("water_holy", 5)
		else
			src.flavor = pick("orange","grape","lemon","cherry","apple","blueberry")


		switch(flavor)
			if("orange")
				R.add_reagent("juice_orange", 5)
				R.add_reagent("oculine", 5)
				R.add_reagent("chickensoup", 5)
				R.add_reagent("screwdriver", 5)
				R.add_reagent("honey_tea", 5)
			if("grape")
				R.add_reagent("wine", 5)
				R.add_reagent("robustissin", 5) //?
				R.add_reagent("coffee", 5)
				R.add_reagent("bread", 5)
				R.add_reagent("milk", 5)
			if("lemon")
				R.add_reagent("juice_lemon", 5)
				R.add_reagent("juice_lime", 5)
				R.add_reagent("luminol", 5)
				R.add_reagent("chalk", 5)
				R.add_reagent("urine", 5)
			if("cherry")
				R.add_reagent("juice_strawberry", 5)
				R.add_reagent("juice_cherry", 5)
				R.add_reagent("blood", 5)
				R.add_reagent("crank", 5)
				R.add_reagent("aranesp", 5)
			if("apple")
				R.add_reagent("juice_apple", 5)
				R.add_reagent("cider", 5)
				R.add_reagent("space_ipecac", 5) //?
				R.add_reagent("gcheese", 5)
				R.add_reagent("hunchback", 5)
			if("blueberry")
				R.add_reagent("juice_blueberry", 5)
				R.add_reagent("mannitol", 5)
				R.add_reagent("haloperidol", 5)
				R.add_reagent("expresso", 5) //?
				R.add_reagent("krokodil", 5)

	heal(var/mob/M)
		..()
		M.bodytemperature = min(M.base_body_temp, M.bodytemperature-20)
		return

	attack_self(var/mob/user)
		if(opened)
			..()
		else
			boutput(user,"<span style=\"color:blue\"><b>You unwrap [src].</b></span>")
			src.open_wrapper(user)

	proc/open_wrapper(var/mob/user)
		src.icon_state = src.flavor
		switch(src.flavor)
			if("orangecreamsicle")
				src.desc = "An orange popsicle, which appears to be \"Oecumenical Orange Creamsicle\" fla- wait, it's a creamsicle? HELL. YES."
			if("orange")
				src.desc = "An orange popsicle, which appears to be \"Cold Case Citrus\" flavor, for opening your sinuses again when you're having a sick day."
			if("grape")
				src.desc = "A purple popsicle, which appears to be \"Raisin' Hell Raisin\" flavor, which features a boost of \"Super Energy Raisin Juice,\" whatever that is."
			if("lemon")
				src.desc = "A yellowish popsicle, which appears to be \"Lemon-Lime Violent Crime\" flavor, with a tang so good it's a crime to sell this cheap."
			if("cherry")
				src.desc = "A red popsicle, which appears to be \"'Roid Rage Redberry\" flavor, guaranteed to put you into a rage until you taste more."
			if("apple")
				src.desc = "A green popsicle, which appears to be \"Green Apple Gastroenteritis\" flavor, which boasts a more active digestive system."
			if("blueberry")
				src.desc = "A blue popsicle, which appears to be \"Batshit Blueberry Brain Hemorrhage\" flavor, which allegedly tastes so good it fries your brain."
		src.opened = 1

		if(prob(8))
			src.melt(user)

	on_finish(mob/eater, var/mob/user)
		var/obj/item/stick/S = new
		user.put_in_hand_or_drop(S)
		..()

	proc/melt(var/mob/user)
		boutput(user,"<span style=\"color:blue\"><b>[src] has already melted! Damn!</b></span>")
		src.reagents.reaction(get_turf(src))
		user.u_equip(src)
		src.set_loc(get_turf(user))
		qdel(src)
		var/obj/item/stick/S = new
		user.put_in_hand_or_drop(S)
		return