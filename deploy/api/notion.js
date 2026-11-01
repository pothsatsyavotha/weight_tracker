// Vercel serverless proxy: keeps the Notion token on the server and avoids CORS.
// Env vars (set in Vercel): NOTION_TOKEN, NOTION_DATABASE_ID, APP_KEY (optional)

const PAGE_ID = /^[0-9a-fA-F-]{32,36}$/;

export default async function handler(req, res) {
  const token = process.env.NOTION_TOKEN;
  const dbId = process.env.NOTION_DATABASE_ID;
  if (!token || !dbId) {
    return res.status(500).json({ message: 'Server not configured: set NOTION_TOKEN and NOTION_DATABASE_ID in Vercel' });
  }

  const appKey = process.env.APP_KEY;
  if (appKey && req.headers['x-app-key'] !== appKey) {
    return res.status(401).json({ message: 'Unauthorized' });
  }

  const path = String(req.query.path || '');
  let url;
  let method = req.method;
  let body = req.body && typeof req.body === 'object' ? { ...req.body } : {};

  if (path === 'query' && method === 'POST') {
    url = `https://api.notion.com/v1/databases/${dbId}/query`;
  } else if (path === 'pages' && method === 'POST') {
    url = 'https://api.notion.com/v1/pages';
    body.parent = { database_id: dbId }; // always write into YOUR database
  } else if (path.startsWith('pages/') && method === 'PATCH') {
    const id = path.slice('pages/'.length);
    if (!PAGE_ID.test(id)) return res.status(400).json({ message: 'Bad page id' });
    url = `https://api.notion.com/v1/pages/${id}`;
  } else {
    return res.status(400).json({ message: 'Unsupported request' });
  }

  try {
    const r = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
    const text = await r.text();
    res.status(r.status).setHeader('Content-Type', 'application/json').send(text);
  } catch (e) {
    res.status(502).json({ message: 'Could not reach Notion' });
  }
}
