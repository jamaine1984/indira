const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');

const openrouterKey = defineSecret('OPENROUTER_API_KEY');

const TEXT_MODELS = [
  'nvidia/nemotron-3-super-120b-a12b:free',
  'minimax/minimax-m2.5:free',
  'stepfun/step-3.5-flash:free',
  'arcee-ai/trinity-large-preview:free',
  'qwen/qwen3-next-80b-a3b-instruct:free',
];

const IMAGE_MODEL = 'google/gemini-3.1-flash-image-preview';

async function callOpenRouter(apiKey, model, messages, retryModels = []) {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://indira-love.web.app',
    },
    body: JSON.stringify({model, messages}),
  });

  const data = await response.json();

  if (data.error) {
    const code = data.error.code;
    const isPaid = data.error.message?.toLowerCase().includes('paid') ||
                   data.error.message?.toLowerCase().includes('credit') ||
                   data.error.message?.toLowerCase().includes('billing');
    const isContext = code === 'context_length_exceeded' ||
                     data.error.message?.toLowerCase().includes('context');

    if ((isContext || isPaid || response.status === 402 || response.status === 429) && retryModels.length > 0) {
      const next = retryModels[0];
      const remaining = retryModels.slice(1);
      console.log(`Model ${model} failed (${code}), falling back to ${next}`);
      return callOpenRouter(apiKey, next, messages, remaining);
    }

    throw new Error(data.error.message || 'OpenRouter API error');
  }

  return {
    content: data.choices?.[0]?.message?.content || '',
    model: data.model || model,
  };
}

exports.generateText = onRequest({
  cors: true,
  secrets: [openrouterKey],
}, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

  const {prompt, app} = req.body;
  if (!prompt) return res.status(400).json({error: 'Missing prompt'});

  try {
    const apiKey = openrouterKey.value();
    const systemPrompt = app === 'nightshift'
      ? 'You are a creative social media marketer for "Night Shift Dating" — a dating app for people who work night shifts, late hours, and non-traditional schedules. Create engaging, relatable content that speaks to night owls and shift workers looking for love.'
      : 'You are a creative social media marketer for "Indira" — a Vedic Kundli dating app that combines ancient Indian astrology with modern dating. Create engaging content that highlights astrology compatibility, Kundli matching, and finding destined love.';

    const result = await callOpenRouter(
      apiKey,
      TEXT_MODELS[0],
      [
        {role: 'system', content: systemPrompt},
        {role: 'user', content: prompt},
      ],
      TEXT_MODELS.slice(1),
    );

    res.json({text: result.content, model: result.model});
  } catch (error) {
    console.error('Text generation error:', error);
    res.status(500).json({error: error.message});
  }
});

exports.generateImage = onRequest({
  cors: true,
  secrets: [openrouterKey],
}, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

  const {prompt} = req.body;
  if (!prompt) return res.status(400).json({error: 'Missing prompt'});

  try {
    const apiKey = openrouterKey.value();

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://indira-love.web.app',
      },
      body: JSON.stringify({
        model: IMAGE_MODEL,
        messages: [
          {
            role: 'user',
            content: `Generate an image: ${prompt}. Only output the image, no text.`,
          },
        ],
      }),
    });

    const data = await response.json();

    if (data.error) {
      throw new Error(data.error.message || 'Image generation failed');
    }

    const message = data.choices?.[0]?.message || {};
    const content = message.content || '';
    const images = message.images || [];

    let imageData = null;

    // OpenRouter Gemini returns images in message.images array
    if (images.length > 0) {
      const img = images[0];
      if (img.image_url?.url) {
        const dataUrl = img.image_url.url;
        const match = dataUrl.match(/^data:(image\/[^;]+);base64,(.+)$/s);
        if (match) {
          imageData = {
            base64: match[2],
            mimeType: match[1],
          };
        }
      }
    }

    // Fallback: check content for base64 data URL
    if (!imageData && content) {
      const base64Match = content.match(/data:(image\/[^;]+);base64,([A-Za-z0-9+/=\s]+)/s);
      if (base64Match) {
        imageData = {
          base64: base64Match[2].replace(/\s/g, ''),
          mimeType: base64Match[1],
        };
      }
    }

    res.json({
      image: imageData,
      content: content,
      model: data.model || IMAGE_MODEL,
    });
  } catch (error) {
    console.error('Image generation error:', error);
    res.status(500).json({error: error.message});
  }
});
