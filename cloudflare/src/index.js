const groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const model = 'qwen/qwen3.8-27b';
const systemPrompt =
  'Дай одну короткую, намеренно расплывчатую смысловую подсказку для русского слова из игры Wordle. Укажи только общий контекст, назначение или ассоциацию: подсказка должна давать направление, но не быть точным определением. Не называй слово, его формы, однокоренные слова и не объясняй правила игры.';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request, environment) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== 'POST' || new URL(request.url).pathname !== '/hint') {
      return response({ error: 'Route not found.' }, 404);
    }

    let word;
    try {
      ({ word } = await request.json());
      word = word.trim().toUpperCase();
    } catch {
      return response({ error: 'Invalid request.' }, 400);
    }

    if (!/^[А-ЯЁ]{3,10}$/.test(word)) {
      return response({ error: 'Invalid word.' }, 400);
    }

    try {
      const groqResponse = await fetch(groqEndpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${environment.GROQ_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          reasoning_effort: 'none',
          temperature: 0.5,
          max_completion_tokens: 48,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: `Слово: ${word}` },
          ],
        }),
      });

      if (!groqResponse.ok) {
        return response({ error: 'Unable to create a hint.' }, 502);
      }

      const payload = await groqResponse.json();
      const hint = payload.choices?.[0]?.message?.content?.trim() ?? '';
      if (!hint || hint.toUpperCase().includes(word)) {
        return response({ error: 'Unable to create a hint.' }, 502);
      }

      return response({ hint });
    } catch {
      return response({ error: 'Unable to create a hint.' }, 502);
    }
  },
};

function response(payload, status) {
  return Response.json(payload, { status, headers: corsHeaders });
}
