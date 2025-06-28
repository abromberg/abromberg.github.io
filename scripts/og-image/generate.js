import { ImageResponse } from '@vercel/og';
import { glob } from 'glob';
import fs from 'fs/promises';
import path from 'path';
import frontMatter from 'front-matter';

async function generateDefaultOGImage() {
  // Load fonts
  const hankenGroteskRegular = await fs.readFile(path.join(process.cwd(), '../../assets/fonts/hanken-grotesk-v8-latin-regular.ttf'));
  const hankenGroteskMedium = await fs.readFile(path.join(process.cwd(), '../../assets/fonts/hanken-grotesk-v8-latin-500.ttf'));

  return new ImageResponse(
    {
      type: 'div',
      props: {
        style: {
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          backgroundColor: '#FFFCF0',
          padding: '60px',
        },
        children: [
          {
            type: 'div',
            props: {
              style: {
                fontSize: 60,
                fontFamily: 'Hanken Grotesk Medium',
                color: '#100F0F',
                lineHeight: 1.2,
                fontWeight: 500,
              },
              children: 'Ways of Looking',
            },
          },
          {
            type: 'div',
            props: {
              style: {
                fontSize: 28,
                fontFamily: 'Hanken Grotesk',
                color: '#6F6E69',
                fontWeight: 400,
              },
              children: 'andybromberg.com',
            },
          },
        ],
      },
    },
    {
      width: 1200,
      height: 630,
      fonts: [
        {
          name: 'Hanken Grotesk',
          data: hankenGroteskRegular,
          weight: 400,
          style: 'normal',
        },
        {
          name: 'Hanken Grotesk Medium',
          data: hankenGroteskMedium,
          weight: 500,
          style: 'normal',
        },
      ],
    }
  );
}

async function generateOGImage(title, date) {
  // Load fonts
  const hankenGroteskRegular = await fs.readFile(path.join(process.cwd(), '../../assets/fonts/hanken-grotesk-v8-latin-regular.ttf'));
  const hankenGroteskMedium = await fs.readFile(path.join(process.cwd(), '../../assets/fonts/hanken-grotesk-v8-latin-500.ttf'));
  const andadaProRegular = await fs.readFile(path.join(process.cwd(), '../../assets/fonts/andada-pro-v21-latin-regular.ttf'));

  return new ImageResponse(
    {
      type: 'div',
      props: {
        style: {
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          backgroundColor: '#FFFCF0',
          padding: '60px',
        },
        children: [
          {
            type: 'div',
            props: {
              style: {
                display: 'flex',
                flexDirection: 'column',
                gap: '20px',
              },
              children: [
                {
                  type: 'div',
                  props: {
                    style: {
                      fontSize: 60,
                      fontFamily: 'Hanken Grotesk Medium',
                      color: '#100F0F',
                      lineHeight: 1.2,
                      fontWeight: 500,
                    },
                    children: title,
                  },
                },
                date && {
                  type: 'div',
                  props: {
                    style: {
                      fontSize: 32,
                      fontFamily: 'Andada Pro',
                      color: '#6F6E69',
                      fontWeight: 400,
                    },
                    children: date,
                  },
                },
              ].filter(Boolean),
            },
          },
          {
            type: 'div',
            props: {
              style: {
                fontSize: 28,
                fontFamily: 'Hanken Grotesk',
                color: '#6F6E69',
                fontWeight: 400,
              },
              children: 'andybromberg.com',
            },
          },
        ],
      },
    },
    {
      width: 1200,
      height: 630,
      fonts: [
        {
          name: 'Hanken Grotesk',
          data: hankenGroteskRegular,
          weight: 400,
          style: 'normal',
        },
        {
          name: 'Hanken Grotesk Medium',
          data: hankenGroteskMedium,
          weight: 500,
          style: 'normal',
        },
        {
          name: 'Andada Pro',
          data: andadaProRegular,
          weight: 400,
          style: 'normal',
        },
      ],
    }
  );
}

async function processFiles() {
  try {
    // Create output directory if it doesn't exist
    await fs.mkdir('../../assets/images/og', { recursive: true });

    // Generate default OG image
    const defaultImageResponse = await generateDefaultOGImage();
    const defaultImageBuffer = await defaultImageResponse.arrayBuffer();
    const defaultOutputPath = path.join('../../assets/images/og', 'og_default.png');
    await fs.writeFile(defaultOutputPath, Buffer.from(defaultImageBuffer));
    console.log('Generated default OG image');

    // Get all markdown files (both .md and .markdown extensions)
    const files = await glob('../../_posts/**/*.{md,markdown}');
    const pages = await glob('../../*.{md,markdown}');
    const allFiles = [...files, ...pages];

    for (const file of allFiles) {
      try {
        const content = await fs.readFile(file, 'utf8');
        const { attributes } = frontMatter(content);
        const { title, date } = attributes;

        if (!title) continue;

        const formattedDate = date ? new Date(date).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        }) : null;

        // Generate OG image
        const imageResponse = await generateOGImage(title, formattedDate);
        const imageBuffer = await imageResponse.arrayBuffer();
        
        // Get the basename without extension and add .png
        const baseName = path.basename(file, path.extname(file));
        const outputPath = path.join('../../assets/images/og', `${baseName}.png`);
        await fs.writeFile(outputPath, Buffer.from(imageBuffer));
        
        console.log(`Generated OG image for: ${title}`);
      } catch (error) {
        console.error(`Error processing file ${file}:`, error);
      }
    }
  } catch (error) {
    console.error('Error in processFiles:', error);
    throw error;
  }
}

processFiles().catch(console.error); 