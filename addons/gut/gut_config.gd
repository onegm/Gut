var Gut = load('res://addons/gut/gut.gd')

# Do not want a ref to _utils here due to use by editor plugin.
# _utils needs to be split so that constants and what not do not
# have to rely on the weird singleton thing I made.
enum DOUBLE_STRATEGY{
	FULL,
	PARTIAL
}


var valid_fonts = ['AnonymousPro', 'CourierPro', 'LobsterTwo', 'Default']
var default_options = {
	background_color = Color(.15, .15, .15, 1).to_html(),
	config_file = 'res://.gutconfig.json',
	dirs = [],
	disable_colors = false,
	double_strategy = 'partial',
	font_color = Color(.8, .8, .8, 1).to_html(),
	font_name = 'CourierPrime',
	font_size = 16,
	headless = false,
	hide_orphans = false,
	ignore_pause = false,
	include_subdirs = false,
	inner_class = '',
	junit_xml_file = '',
	junit_xml_timestamp = false,
	log_level = 1,
	opacity = 100,
	post_run_script = '',
	pre_run_script = '',
	prefix = 'test_',
	selected = '',
	should_exit = false,
	should_exit_on_success = false,
	should_maximize = false,
	compact_mode = false,
	show_help = false,
	suffix = '.gd',
	tests = [],
	unit_test_name = '',

	gut_on_top = true,
}

var default_panel_options = {
	font_name = 'CourierPrime',
	font_size = 30
}

var options = default_options.duplicate()


func _null_copy(h):
	var new_hash = {}
	for key in h:
		new_hash[key] = null
	return new_hash


func _load_options_from_config_file(file_path, into):
	# SHORTCIRCUIT
	var f = File.new()
	if(!f.file_exists(file_path)):
		if(file_path != 'res://.gutconfig.json'):
			print('ERROR:  Config File "', file_path, '" does not exist.')
			return -1
		else:
			return 1

	var result = f.open(file_path, f.READ)
	if(result != OK):
		push_error(str("Could not load data ", file_path, ' ', result))
		return result

	var json = f.get_as_text()
	f.close()

	var results = JSON.parse(json)
	# SHORTCIRCUIT
	if(results.error != OK):
		print("\n\n",'!! ERROR parsing file:  ', file_path)
		print('    at line ', results.error_line, ':')
		print('    ', results.error_string)
		return -1

	# Get all the options out of the config file using the option name.  The
	# options hash is now the default source of truth for the name of an option.
	for key in into:
		if(results.result.has(key)):
			if(results.result[key] != null):
				into[key] = results.result[key]

	return 1


func write_options(path):
	var content = JSON.print(options, ' ')

	var f = File.new()
	var result = f.open(path, f.WRITE)
	if(result == OK):
		f.store_string(content)
		f.close()
	return result


# Apply all the options specified to _tester.  This is where the rubber meets
# the road.
func _apply_options(opts, tester):
	if(opts.headless):
		opts.should_exit = true
		opts.should_exit_on_success = false
		opts.ignore_pause = true
		tester.get_logger().disable_printer('gui', true)

	tester.set_yield_between_tests(true)
	tester.set_modulate(Color(1.0, 1.0, 1.0, min(1.0, float(opts.opacity) / 100)))
	tester.show()

	tester.set_include_subdirectories(opts.include_subdirs)

	if(opts.should_maximize):
		tester.maximize()

	if(opts.compact_mode):
		tester.get_gui().compact_mode(true)

	if(opts.inner_class != ''):
		tester.set_inner_class_name(opts.inner_class)
	tester.set_log_level(opts.log_level)
	tester.set_ignore_pause_before_teardown(opts.ignore_pause)

	for i in range(opts.dirs.size()):
		tester.add_directory(opts.dirs[i], opts.prefix, opts.suffix)

	for i in range(opts.tests.size()):
		tester.add_script(opts.tests[i])

	if(opts.selected != ''):
		tester.select_script(opts.selected)
		# _run_single = true

	if(opts.double_strategy == 'full'):
		tester.set_double_strategy(DOUBLE_STRATEGY.FULL)
	elif(opts.double_strategy == 'partial'):
		tester.set_double_strategy(DOUBLE_STRATEGY.PARTIAL)

	tester.set_unit_test_name(opts.unit_test_name)
	tester.set_pre_run_script(opts.pre_run_script)
	tester.set_post_run_script(opts.post_run_script)
	tester.set_color_output(!opts.disable_colors)
	tester.show_orphans(!opts.hide_orphans)
	tester.set_junit_xml_file(opts.junit_xml_file)
	tester.set_junit_xml_timestamp(opts.junit_xml_timestamp)

	tester.get_gui().set_font_size(opts.font_size)
	tester.get_gui().set_font(opts.font_name)
	if(opts.font_color != null and opts.font_color.is_valid_html_color()):
		tester.get_gui().set_default_font_color(Color(opts.font_color))
	if(opts.background_color != null and opts.background_color.is_valid_html_color()):
		tester.get_gui().set_background_color(Color(opts.background_color))

	return tester


func config_gut(gut):
	return _apply_options(options, gut)


func load_options(path):
	return _load_options_from_config_file(path, options)

func load_panel_options(path):
	options['panel_options'] = default_panel_options.duplicate()
	return _load_options_from_config_file(path, options)

func load_options_no_defaults(path):
	options = _null_copy(default_options)
	return _load_options_from_config_file(path, options)

func apply_options(gut):
	_apply_options(options, gut)
