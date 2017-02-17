class questionnaire extends AnnotationIteration

  _this = undefined
  questionsQuery = '.interfaces-staging >:not(.template) .questions-container .question'
  qestionTemplatesQuery = '.interfaces-staging >:not(.template) .question-templates'

  # uncomment to overwrite interface registration at AnnotationLifecylce
  constructor: ->
    _this = this
    this.$questions = $(questionsQuery)
    this.questions = []

    this.initQuestions()
    this.initInputEventHandler()

    $(document).unbind('keydown')
    $(document).scrollTop(0)

    super

  initQuestions: ->
    this.$questions.each (_, element) ->
      $question = $(element)
      question = {
        $question: $question,
        mandatory: $question.data('mandatory'),
        scale: $question.data('scale'),
        placeholder: $question.data('placeholder'),
        dependence: {
          id: $question.data('dependence-id'),
          selection_condition: $question.data('dependence-selection-condition')
        },
        value_type: $question.data('value-type'),
        value_unit: $question.data('value-unit'),
        values: $question.data('values'),
        bounds: {
          lower: {
            value: $question.data('bounds-lower-value'),
            label: $question.data('bounds-lower-label')
          },
          upper: {
            value: $question.data('bounds-upper-value'),
            label: $question.data('bounds-upper-label')
          }
        },
        id: $question.data('id'),
        selected: -1
      }
      _this.questions.push(question)

      if question.scale == 'interval'
        $('input', element).attr('name', question.id)

      else if question.scale == 'ratio'
        _this.renderFader(question, element)

      else if question.scale == 'string'
        _this.renderTextInput(question, element)

      if question.dependence.id
        $question.hide()
        $("input[name = '#{question.dependence.id}']").change ->
          if $(this).val() == question.dependence.selection_condition
            $question.show()
          else
            $question.hide()

  initInputEventHandler: ->
    $("#{questionsQuery} input[type=radio]").click ->
      $(this).parent().parent().parent().find('.title').removeClass('unanswered')

    $rangeInputQuestions = $('.interfaces-staging >:not(.template) .questions-container .ratio-scale-question')
    $rangeInputQuestions.mousedown ->
      $('.range-value', this).removeClass('was-set')

    $rangeInputQuestions.mouseout ->
      $('.range-value', this).addClass('was-set')

  renderFader: (question, context) ->
    raw_template = $("#{qestionTemplatesQuery} .ratio-scale-question")[0].outerHTML
    left_prepared_template = raw_template.replace(new RegExp('{#{', 'g'), '\{\{')
    prepared_template = left_prepared_template.replace(new RegExp('}#}', 'g'), '\}\}')

    renderedTemplate = Mustache.render(prepared_template, question)
    $('.question-values', context).html(renderedTemplate)

    $faderInput = $('.ratio-scale-question input', context)
    initValue = ($faderInput.attr('max') - $faderInput.attr('min')) / 2
    $faderInput.attr('value', initValue)

  renderTextInput: (question, context) ->
    raw_template = $("#{qestionTemplatesQuery} .string-scale-question")[0].outerHTML
    left_prepared_template = raw_template.replace(new RegExp('{#{', 'g'), '\{\{')
    prepared_template = left_prepared_template.replace(new RegExp('}#}', 'g'), '\}\}')

    renderedTemplate = Mustache.render(prepared_template, question)
    $('.question-values', context).html(renderedTemplate)

  updateRangeTooltip: (value, unit, rangeId) ->
    $tooltip = $(".#{rangeId}-question .range-value")
    $tooltip.html("#{value} #{unit}")
    normalized_value = (value * 100) / $("input##{rangeId}").attr('max')
    percentageFromLeft = 22.2 + ((normalized_value / 2) * 0.92)
    $tooltip.css('left', "#{percentageFromLeft}%")

  render: (template, data) ->
    window.questionnairePayload = data
    super

  saveAnnotation: ->
    answers = []
    mandatoryQuestionUnanswered = false

    for question in this.questions
      answer = {
        id: question.id,
        scale: question.scale
      }

      if question.scale == 'interval'
        value = $("input[name = '#{question.id}']:checked").val()
        if !value && question.mandatory
          question.$question.find('.title').addClass('unanswered')
          mandatoryQuestionUnanswered = true
        else
          answer.selected = value

      else if question.scale == 'string'
        value = $("input##{question.id}").val()
        if !value && question.mandatory
          question.$question.find('.title').addClass('unanswered')
          mandatoryQuestionUnanswered = true
        else
          answer.selected = value

      else if question.scale == 'ratio'
        answer.selected = question.$question.find('input').val()
        # ratio scaled questions have no mandatory check, because they have a default value

      answers.push(answer)

    console.log 'answers:', answers
    this.saveChanges({ content: answers }) unless mandatoryQuestionUnanswered

window.questionnaire = new questionnaire()
