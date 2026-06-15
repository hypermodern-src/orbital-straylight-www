// Authoritative render of Radix Themes 3 — the GOLDEN source. Each component (and
// the composed Sign-in demo) renders in isolation keyed by ?c=<id>, so Playwright
// screenshots one per page; the index (no ?c=) is the human-reviewable gallery.
// This is upstream's real output — the Halogen port is pixel-diffed against it.
import React from "react";
import { createRoot } from "react-dom/client";
import "@radix-ui/themes/styles.css";
// Bundle Inter (Radix Themes' intended typeface) so the render is deterministic —
// headless Chromium has no system sans; without this the golden falls back to mono.
import "@fontsource-variable/inter";
import {
  Theme,
  Button,
  Checkbox,
  Switch,
  TextField,
  TextArea,
  Card,
  Separator,
  Badge,
  Callout,
  Avatar,
  Spinner,
  Progress,
  Code,
  Kbd,
  Quote,
  Blockquote,
  Em,
  Strong,
  Link,
  RadioGroup,
  Slider,
  Tabs,
  Table,
  DataList,
  Flex,
  Box,
  Text,
  Heading,
} from "@radix-ui/themes";

type Page = { id: string; label: string; node: React.ReactNode };

const PAGES: Page[] = [
  {
    id: "button",
    label: "Button",
    node: (
      <Flex direction="column" gap="3" align="start">
        <Flex gap="3" align="center">
          <Button variant="solid">Solid</Button>
          <Button variant="soft">Soft</Button>
          <Button variant="outline">Outline</Button>
          <Button variant="surface">Surface</Button>
          <Button variant="ghost">Ghost</Button>
        </Flex>
        <Flex gap="3" align="center">
          <Button size="1">Size 1</Button>
          <Button size="2">Size 2</Button>
          <Button size="3">Size 3</Button>
          <Button disabled>Disabled</Button>
        </Flex>
      </Flex>
    ),
  },
  {
    id: "checkbox",
    label: "Checkbox",
    node: (
      <Flex direction="column" gap="2">
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox defaultChecked /> Checked
          </Flex>
        </Text>
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox /> Unchecked
          </Flex>
        </Text>
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox disabled defaultChecked /> Disabled
          </Flex>
        </Text>
      </Flex>
    ),
  },
  {
    id: "switch",
    label: "Switch",
    node: (
      <Flex gap="4" align="center">
        <Switch defaultChecked />
        <Switch />
        <Switch disabled defaultChecked />
        <Switch size="1" defaultChecked />
        <Switch size="3" defaultChecked />
      </Flex>
    ),
  },
  {
    id: "textfield",
    label: "TextField",
    node: (
      <Flex direction="column" gap="3" style={{ maxWidth: 320 }}>
        <TextField.Root placeholder="Search the docs…" />
        <TextField.Root size="3" placeholder="Larger field" defaultValue="m@example.com" />
      </Flex>
    ),
  },
  {
    id: "textarea",
    label: "TextArea",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <TextArea placeholder="Reply to comment…" />
      </Box>
    ),
  },
  {
    id: "badge",
    label: "Badge",
    node: (
      <Flex gap="2" align="center">
        <Badge color="green">Complete</Badge>
        <Badge color="orange">In progress</Badge>
        <Badge color="red">Failed</Badge>
        <Badge variant="solid">Solid</Badge>
      </Flex>
    ),
  },
  {
    id: "callout",
    label: "Callout",
    node: (
      <Box style={{ maxWidth: 420 }}>
        <Callout.Root>
          <Callout.Text>
            You will need admin privileges to install and access this application.
          </Callout.Text>
        </Callout.Root>
      </Box>
    ),
  },
  {
    id: "card",
    label: "Card",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <Card>
          <Flex gap="3" align="center">
            <Box>
              <Text as="div" size="2" weight="bold">
                Teodros Girmay
              </Text>
              <Text as="div" size="2" color="gray">
                Engineering
              </Text>
            </Box>
          </Flex>
        </Card>
      </Box>
    ),
  },
  {
    id: "avatar",
    label: "Avatar",
    node: (
      <Flex gap="3" align="center">
        <Avatar fallback="A" />
        <Avatar fallback="TG" color="indigo" />
        <Avatar fallback="RT" variant="solid" />
        <Avatar size="5" fallback="L" />
      </Flex>
    ),
  },
  {
    id: "spinner",
    label: "Spinner",
    node: (
      <Flex gap="4" align="center">
        <Spinner size="1" />
        <Spinner size="2" />
        <Spinner size="3" />
      </Flex>
    ),
  },
  {
    id: "progress",
    label: "Progress",
    node: (
      <Flex direction="column" gap="4" style={{ maxWidth: 320 }}>
        <Progress value={25} />
        <Progress value={60} color="cyan" />
        <Progress value={90} variant="soft" />
      </Flex>
    ),
  },
  {
    id: "separator",
    label: "Separator",
    node: (
      <Flex direction="column" gap="3" style={{ maxWidth: 240 }}>
        <Text size="2">Above</Text>
        <Separator size="4" />
        <Text size="2">Below</Text>
      </Flex>
    ),
  },
  {
    id: "code",
    label: "Code",
    node: (
      <Text size="3">
        Run <Code>npm install</Code> then <Code variant="solid">npm start</Code>.
      </Text>
    ),
  },
  {
    id: "kbd",
    label: "Kbd",
    node: (
      <Text size="3">
        Press <Kbd>Shift + Tab</Kbd> to go back.
      </Text>
    ),
  },
  {
    id: "quote",
    label: "Quote",
    node: (
      <Text size="3">
        <Quote>Design is not just what it looks like and feels like.</Quote>
      </Text>
    ),
  },
  {
    id: "blockquote",
    label: "Blockquote",
    node: (
      <Box style={{ maxWidth: 360 }}>
        <Blockquote>
          Perfect is the enemy of good. Ship the thing, then make it better.
        </Blockquote>
      </Box>
    ),
  },
  {
    id: "emstrong",
    label: "Em / Strong",
    node: (
      <Text size="3">
        The <Strong>quick</Strong> brown fox is <Em>remarkably</Em> fast.
      </Text>
    ),
  },
  {
    id: "link",
    label: "Link",
    node: (
      <Text size="3">
        Read the <Link href="#">documentation</Link> for more.
      </Text>
    ),
  },
  {
    id: "radiogroup",
    label: "RadioGroup",
    node: (
      <RadioGroup.Root defaultValue="1">
        <Flex direction="column" gap="2">
          <Text as="label" size="2">
            <Flex gap="2" align="center">
              <RadioGroup.Item value="1" /> Default
            </Flex>
          </Text>
          <Text as="label" size="2">
            <Flex gap="2" align="center">
              <RadioGroup.Item value="2" /> Comfortable
            </Flex>
          </Text>
          <Text as="label" size="2">
            <Flex gap="2" align="center">
              <RadioGroup.Item value="3" /> Compact
            </Flex>
          </Text>
        </Flex>
      </RadioGroup.Root>
    ),
  },
  {
    id: "slider",
    label: "Slider",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <Slider defaultValue={[40]} />
      </Box>
    ),
  },
  {
    id: "tabs",
    label: "Tabs",
    node: (
      <Tabs.Root defaultValue="account">
        <Tabs.List>
          <Tabs.Trigger value="account">Account</Tabs.Trigger>
          <Tabs.Trigger value="documents">Documents</Tabs.Trigger>
          <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
        </Tabs.List>
      </Tabs.Root>
    ),
  },
  {
    id: "table",
    label: "Table",
    node: (
      <Box style={{ maxWidth: 480 }}>
        <Table.Root>
          <Table.Header>
            <Table.Row>
              <Table.ColumnHeaderCell>Name</Table.ColumnHeaderCell>
              <Table.ColumnHeaderCell>Email</Table.ColumnHeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            <Table.Row>
              <Table.RowHeaderCell>Danilo</Table.RowHeaderCell>
              <Table.Cell>danilo@example.com</Table.Cell>
            </Table.Row>
            <Table.Row>
              <Table.RowHeaderCell>Zahra</Table.RowHeaderCell>
              <Table.Cell>zahra@example.com</Table.Cell>
            </Table.Row>
          </Table.Body>
        </Table.Root>
      </Box>
    ),
  },
  {
    id: "datalist",
    label: "DataList",
    node: (
      <DataList.Root>
        <DataList.Item>
          <DataList.Label>Status</DataList.Label>
          <DataList.Value>
            <Badge color="jade">Authorized</Badge>
          </DataList.Value>
        </DataList.Item>
        <DataList.Item>
          <DataList.Label>Name</DataList.Label>
          <DataList.Value>Vlad Moroz</DataList.Value>
        </DataList.Item>
      </DataList.Root>
    ),
  },
  // The composed demo — the "looks like a finished product" target.
  {
    id: "signin",
    label: "Sign-in card",
    node: (
      <Box style={{ maxWidth: 400 }}>
        <Card size="4">
          <Heading as="h3" size="6" trim="start" mb="5">
            Sign in
          </Heading>
          <Box mb="5">
            <Flex direction="column" gap="1">
              <Text as="label" size="2" weight="medium">
                Email address
              </Text>
              <TextField.Root placeholder="you@example.com" />
            </Flex>
          </Box>
          <Box mb="5">
            <Flex direction="column" gap="1">
              <Flex justify="between">
                <Text as="label" size="2" weight="medium">
                  Password
                </Text>
                <Text size="2">
                  <a href="#">Forgot password?</a>
                </Text>
              </Flex>
              <TextField.Root placeholder="Enter your password" />
            </Flex>
          </Box>
          <Flex align="center" gap="2" mb="5">
            <Text as="label" size="2">
              <Flex gap="2" align="center">
                <Checkbox defaultChecked /> Remember me
              </Flex>
            </Text>
          </Flex>
          <Flex justify="end" gap="3">
            <Button variant="soft" color="gray">
              Create account
            </Button>
            <Button>Sign in</Button>
          </Flex>
        </Card>
      </Box>
    ),
  },
];

function currentId(): string {
  const m = location.search.match(/[?&]c=([^&]+)/);
  return m ? decodeURIComponent(m[1]) : "";
}

function Index() {
  return (
    <Box p="6" style={{ maxWidth: 900, margin: "0 auto" }}>
      <Heading size="7" mb="1">
        Radix Themes 3.3.0 — golden source
      </Heading>
      <Text as="p" color="gray" mb="5">
        Upstream render. Each card is the authoritative target the Halogen port is
        pixel-diffed against. Click a title to see it isolated (the Playwright page).
      </Text>
      <Flex direction="column" gap="4">
        {PAGES.map((p) => (
          <Card key={p.id} size="2">
            <Heading size="2" mb="3" color="gray">
              <a href={`?c=${p.id}`} style={{ color: "inherit", textDecoration: "none" }}>
                {p.label}
              </a>
            </Heading>
            {p.node}
          </Card>
        ))}
      </Flex>
    </Box>
  );
}

const id = currentId();
const page = PAGES.find((p) => p.id === id);
const content = page ? <Box p="6">{page.node}</Box> : <Index />;

createRoot(document.getElementById("root")!).render(
  <Theme
    accentColor="indigo"
    grayColor="slate"
    radius="medium"
    appearance="light"
    style={{ ["--default-font-family" as string]: "'Inter Variable', sans-serif" }}
  >
    {content}
  </Theme>,
);
