#!/usr/bin/env ruby

PARAMETERS = {
  :simultaneous_threshold_milliseconds => 500,
}.freeze

require 'json'
require_relative '../lib/karabiner.rb'

def main
  puts JSON.pretty_generate(
    "title" => "Personal rules (@sidharthv96)",
    "rules" => [
      {
        "description" => "Diamond Nav Mode [; as Trigger Key]",
        "manipulators" => generate_diamond_mode("semicolon", ['i', 'k', 'j', 'l']),
      },
      {
        "description" => "jkl; Nav Mode [E as Trigger Key]",
        "manipulators" => generate_diamond_mode("e", ['k', 'j', 'l', 'semicolon']),
      },
      {
        "description" => "Change delete_or_backspace key to hyper and caps_lock to delete_or_backspace.",
        "manipulators" => [
          {
            "type" => "basic",
            "from" => _from("delete_or_backspace", [], ['any']),
            "to" => _to([["left_shift", [
              "left_command",
              "left_control",
              "left_option"
            ]]]),
          },
          {
            "type" => "basic",
            "from" => _from("caps_lock", [], ['any']),
            "to" => _to([["delete_or_backspace", []]]),
          },
        ]
      },
      {
        'description' => 'Mouse Keys Mode',
        'manipulators' => [

          # jkl; colemak

          generate_mouse_keys_mode('j',
                                   [{ 'mouse_key' => { 'y' => 768} }],
                                   [{ 'mouse_key' => { 'vertical_wheel' => 32 } }],
                                   nil),
          generate_mouse_keys_mode('k',
                                   [{ 'mouse_key' => { 'y' => -768 } }],
                                   [{ 'mouse_key' => { 'vertical_wheel' => -32 } }],
                                   nil),
          generate_mouse_keys_mode('l',
                                   [{ 'mouse_key' => { 'x' => -768 } }],
                                   [{ 'mouse_key' => { 'horizontal_wheel' => 32 } }],
                                   nil),
          generate_mouse_keys_mode('semicolon',
                                   [{ 'mouse_key' => { 'x' => 768 } }],
                                   [{ 'mouse_key' => { 'horizontal_wheel' => -32 } }],
                                   nil),

          # buttons

          generate_mouse_keys_mode('v',
                                   [{ 'pointing_button' => 'button1' }],
                                   nil,
                                   nil),

          generate_mouse_keys_mode('b',
                                   [{ 'pointing_button' => 'button3' }],
                                   nil,
                                   nil),

          generate_mouse_keys_mode('n',
                                   [{ 'pointing_button' => 'button2' }],
                                   nil,
                                   nil),

          # others

          generate_mouse_keys_mode('s',
                                   [Karabiner.set_variable('sidv_mouse_keys_mode_v4_scroll', 1)],
                                   nil,
                                   [Karabiner.set_variable('sidv_mouse_keys_mode_v4_scroll', 0)]),
          generate_mouse_keys_mode('f',
                                   [{ 'mouse_key' => { 'speed_multiplier' => 2.0 } }],
                                   nil,
                                   nil),
          generate_mouse_keys_mode('g',
                                   [{ 'mouse_key' => { 'speed_multiplier' => 0.5 } }],
                                   nil,
                                   nil),
        ].flatten,
      }
    ],
  )
end


def _from(key_code, mandatory_modifiers, optional_modifiers)
  data = {}
  data['key_code'] = key_code

  mandatory_modifiers.each do |m|
    data['modifiers'] = {} if data['modifiers'].nil?
    data['modifiers']['mandatory'] = [] if data['modifiers']['mandatory'].nil?
    data['modifiers']['mandatory'] << m
  end

  optional_modifiers.each do |m|
    data['modifiers'] = {} if data['modifiers'].nil?
    data['modifiers']['optional'] = [] if data['modifiers']['optional'].nil?
    data['modifiers']['optional'] << m
  end
  data
end


def _to(events)
  data = []

  events.each do |e|
    d = {}
    d['key_code'] = e[0]
    e[1].nil? || d['modifiers'] = e[1]

    data << d
  end
  data
end

def generate_diamond_mode(trigger_key, arrows)
  [
    generate_diamond_mode_single_rule(arrows[0], "up_arrow", [], trigger_key),
    generate_diamond_mode_single_rule(arrows[1], "down_arrow", [], trigger_key),
    generate_diamond_mode_single_rule(arrows[2], "left_arrow", [], trigger_key),
    generate_diamond_mode_single_rule(arrows[3], "right_arrow", [], trigger_key),
  ].flatten
end


def generate_diamond_mode_single_rule(from_key_code, to_key_code, to_modifier_key_code_array, trigger_key)
  [
    {
      "type" => "basic",
      "from" => {
        "key_code" => from_key_code,
        "modifiers" => { "optional" => ["any"] },
      },
      "to" => [
        {
          "key_code" => to_key_code,
          "modifiers" => to_modifier_key_code_array
        },
      ],
      "conditions" => [
        Karabiner.variable_if('sidv_diamond_mode', 1),
      ]
    },

    {
      "type" => "basic",
      "from" => {
        "simultaneous" => [
          { "key_code" => trigger_key },
          { "key_code" => from_key_code },
        ],
        "simultaneous_options" => {
          "key_down_order" => "strict",
          "key_up_order" => "strict_inverse",
          "detect_key_down_uninterruptedly" => true,
          "to_after_key_up" => [
            Karabiner.set_variable("sidv_diamond_mode", 0),
          ],
        },
        "modifiers" => { "optional" => ["any"] },
      },
      "to" => [
        Karabiner.set_variable("sidv_diamond_mode", 1),
        {
          "key_code" => to_key_code,
          "modifiers" => to_modifier_key_code_array
        }
      ]
    }
  ]
end


def generate_mouse_keys_mode(from_key_code, to, scroll_to, to_after_key_up)
  data = []

  ############################################################

  unless scroll_to.nil?
    h = {
      'type' => 'basic',
      'from' => {
        'key_code' => from_key_code,
        'modifiers' => Karabiner.from_modifiers,
      },
      'to' => scroll_to,
      'conditions' => [
        Karabiner.variable_if('sidv_mouse_keys_mode_v4', 1),
        Karabiner.variable_if('sidv_mouse_keys_mode_v4_scroll', 1),
      ],
    }

    h['to_after_key_up'] = to_after_key_up unless to_after_key_up.nil?

    data << h
  end

  ############################################################

  h = {
    'type' => 'basic',
    'from' => {
      'key_code' => from_key_code,
      'modifiers' => Karabiner.from_modifiers,
    },
    'to' => to,
    'conditions' => [Karabiner.variable_if('sidv_mouse_keys_mode_v4', 1)],
  }

  h['to_after_key_up'] = to_after_key_up unless to_after_key_up.nil?

  data << h

  ############################################################

  h = {
    'type' => 'basic',
    'from' => {
      'simultaneous' => [
        {
          'key_code' => 'd',
        },
        {
          'key_code' => from_key_code,
        },
      ],
      'simultaneous_options' => {
        'key_down_order' => 'strict',
        'key_up_order' => 'strict_inverse',
        'to_after_key_up' => [
          Karabiner.set_variable('sidv_mouse_keys_mode_v4', 0),
          Karabiner.set_variable('sidv_mouse_keys_mode_v4_scroll', 0),
        ],
      },
      'modifiers' => Karabiner.from_modifiers,
    },
    'to' => [
      Karabiner.set_variable('sidv_mouse_keys_mode_v4', 1),
    ].concat(to),
    'parameters' => {
      'basic.simultaneous_threshold_milliseconds' => PARAMETERS[:simultaneous_threshold_milliseconds],
    },
  }

  h['to_after_key_up'] = to_after_key_up unless to_after_key_up.nil?

  data << h

  ############################################################

  data
end

main()
