/datum/random_event/special/skeletons
	name = "Closet Skeletons"

	admin_call(var/source)
		if (..())
			return

		var/select = input(usr, "How many skeletons to spawn (1-50)?", "Number of skeletons") as null|num

		select = max(1,select)
		select = min(50,select)

		src.event_effect(source, select)
		return

	event_effect(var/source, var/spawn_amount_selected = 0)
		..()
		var/spawn_amount = rand(7,13)
		if(spawn_amount_selected)
			spawn_amount = spawn_amount_selected
		var/list/closets = list()
		for(var/obj/storage/closet/C)
			if(get_turf(C).z != 2)
				continue
			else
				closets += C
		for(var/i = 0, i<spawn_amount, i++)
			if(closets.len > 0)
				var/obj/storage/closet/temp = pick(closets)
				new/obj/critter/magiczombie(temp)
				temp.visible_message("<span style=\"color:red\"><b>[temp]</b> emits a loud thump and rattles a bit.</span>")
				playsound(get_turf(temp), "sound/effects/bang.ogg", 50, 1)
				var/wiggle = 6
				while(wiggle > 0)
					wiggle--
					temp.pixel_x = rand(-3,3)
					temp.pixel_y = rand(-3,3)
					sleep(1)
				temp.pixel_x = 0
				temp.pixel_y = 0
				world.log << "Closet At [temp.x],[temp.y],[temp.z] just recieved a spooky skeleton!"
				closets -= temp
			else
				break

		closets = null